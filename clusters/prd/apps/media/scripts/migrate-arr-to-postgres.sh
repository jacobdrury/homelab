#!/usr/bin/env bash
# Migrate Sonarr ×2 + Prowlarr from SQLite (config PVC) → media-pg (CNPG).
# Follows Servarr wiki: boot once on empty PG (schema) → stop → wipe seed rows →
# pgloader data-only → fix sequences → start.
#
# Usage (from repo root):
#   source connect/env.sh
#   ./clusters/prd/apps/media/scripts/migrate-arr-to-postgres.sh
set -eo pipefail

NS=media
PGLOADER_IMAGE=ghcr.io/roxedus/pgloader@sha256:1a7a86ad56623c00ee714ee4969913ed5c6f59ac9785073e2ffd1bea9cc54d31
PGHOST=media-pg-rw.media.svc.cluster.local
PGUSER=$(kubectl -n "${NS}" get secret media-pg-owner -o jsonpath='{.data.username}' | base64 -d)
PGPASS=$(kubectl -n "${NS}" get secret media-pg-owner -o jsonpath='{.data.password}' | base64 -d)

APPS=(sonarr-anime sonarr-tv prowlarr)

sqlite_name() {
  case "$1" in
    sonarr-anime|sonarr-tv) echo sonarr.db ;;
    prowlarr) echo prowlarr.db ;;
  esac
}

logs_sqlite_name() {
  case "$1" in
    sonarr-anime|sonarr-tv|prowlarr) echo logs.db ;;
  esac
}

main_db() {
  case "$1" in
    sonarr-anime) echo sonarr_anime_main ;;
    sonarr-tv) echo sonarr_tv_main ;;
    prowlarr) echo prowlarr_main ;;
  esac
}

log_db() {
  case "$1" in
    sonarr-anime) echo sonarr_anime_log ;;
    sonarr-tv) echo sonarr_tv_log ;;
    prowlarr) echo prowlarr_log ;;
  esac
}

pvc_for() {
  case "$1" in
    sonarr-anime) echo sonarr-anime-config ;;
    sonarr-tv) echo sonarr-tv-config ;;
    prowlarr) echo prowlarr-config ;;
  esac
}

seed_delete_sql() {
  # Servarr wiki seed tables (present after first PG boot).
  cat <<'SQL'
DELETE FROM "QualityProfiles";
DELETE FROM "QualityDefinitions";
DELETE FROM "DelayProfiles";
DELETE FROM "Metadata";
DELETE FROM "Config";
DELETE FROM "VersionInfo";
DELETE FROM "ScheduledTasks";
SQL
}

echo "==> Waiting for media-pg healthy"
kubectl -n "${NS}" wait --for=condition=Ready cluster/media-pg --timeout=300s
for db in sonarr_anime_main sonarr_anime_log sonarr_tv_main sonarr_tv_log prowlarr_main prowlarr_log; do
  kubectl -n "${NS}" wait --for=jsonpath='{.status.applied}'=true "database/${db//_/-}" --timeout=180s 2>/dev/null \
    || kubectl -n "${NS}" get database -o name | head
done
# Database CR names use hyphens; wait individually
for cr in sonarr-anime-main sonarr-anime-log sonarr-tv-main sonarr-tv-log prowlarr-main prowlarr-log; do
  echo "  waiting database/${cr}"
  for _ in $(seq 1 60); do
    applied=$(kubectl -n "${NS}" get "database/${cr}" -o jsonpath='{.status.applied}' 2>/dev/null || echo "")
    [[ "${applied}" == "true" ]] && break
    sleep 3
  done
done

echo "==> Schema bootstrap: ensure apps are up once against Postgres"
kubectl -n "${NS}" scale deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr --replicas=1
kubectl -n "${NS}" rollout status deploy/sonarr-anime --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-tv --timeout=180s
kubectl -n "${NS}" rollout status deploy/prowlarr --timeout=180s
# Give FluentMigrator time to create schema
sleep 20

echo "==> Scale down for pgloader"
kubectl -n "${NS}" scale deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr --replicas=0
kubectl -n "${NS}" wait --for=delete pod -l 'app.kubernetes.io/name in (sonarr-anime,sonarr-tv,prowlarr)' --timeout=180s || true

psql_exec() {
  local db="$1"
  local sql="$2"
  kubectl -n "${NS}" run "psql-$(date +%s)-$RANDOM" --rm -i --restart=Never \
    --image=ghcr.io/cloudnative-pg/postgresql:17.6 \
    --env="PGPASSWORD=${PGPASS}" \
    --overrides="{
      \"spec\": {
        \"nodeSelector\": {\"node-role.kubernetes.io/control-plane\": \"\"},
        \"tolerations\": [{\"key\": \"node-role.kubernetes.io/control-plane\", \"operator\": \"Exists\", \"effect\": \"NoSchedule\"}],
        \"containers\": [{
          \"name\": \"psql\",
          \"image\": \"ghcr.io/cloudnative-pg/postgresql:17.6\",
          \"command\": [\"psql\", \"-h\", \"${PGHOST}\", \"-U\", \"${PGUSER}\", \"-d\", \"${db}\", \"-v\", \"ON_ERROR_STOP=1\", \"-c\", $(python3 -c "import json,sys; print(json.dumps('''${sql}'''))" 2>/dev/null || echo "\"${sql}\"")],
          \"env\": [{\"name\": \"PGPASSWORD\", \"value\": \"${PGPASS}\"}]
        }],
        \"restartPolicy\": \"Never\"
      }
    }" 2>/dev/null || \
  kubectl -n "${NS}" exec -i "media-pg-1" -c postgres -- \
    env PGPASSWORD="${PGPASS}" psql -U "${PGUSER}" -d "${db}" -v ON_ERROR_STOP=1 -c "${sql}"
}

# Prefer exec into CNPG primary pod
cnpg_psql() {
  local db="$1"
  local sql="$2"
  kubectl -n "${NS}" exec -i media-pg-1 -c postgres -- \
    env PGPASSWORD="${PGPASS}" psql -h 127.0.0.1 -U "${PGUSER}" -d "${db}" -v ON_ERROR_STOP=1 <<< "${sql}"
}

migrate_one() {
  local app="$1"
  local pvc sqlite logs_sqlite mdb ldb
  pvc="$(pvc_for "${app}")"
  sqlite="$(sqlite_name "${app}")"
  logs_sqlite="$(logs_sqlite_name "${app}")"
  mdb="$(main_db "${app}")"
  ldb="$(log_db "${app}")"

  echo "==> ${app}: wipe PG seed rows in ${mdb}"
  cnpg_psql "${mdb}" "$(seed_delete_sql)" || true

  echo "==> ${app}: copy sqlite out of PVC ${pvc}"
  kubectl -n "${NS}" delete pod "pgload-${app}" --ignore-not-found --wait=true
  kubectl -n "${NS}" run "pgload-${app}" \
    --image="${PGLOADER_IMAGE}" \
    --restart=Never \
    --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "pgloader",
      "image": "${PGLOADER_IMAGE}",
      "command": ["sleep", "3600"],
      "env": [
        {"name": "PGPASSWORD", "value": "${PGPASS}"}
      ],
      "volumeMounts": [
        {"name": "cfg", "mountPath": "/config"},
        {"name": "work", "mountPath": "/work"}
      ]
    }],
    "volumes": [
      {"name": "cfg", "persistentVolumeClaim": {"claimName": "${pvc}"}},
      {"name": "work", "emptyDir": {}}
    ],
    "restartPolicy": "Never",
    "nodeSelector": {"node-role.kubernetes.io/control-plane": ""},
    "tolerations": [{"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"}]
  }
}
EOF
)"
  kubectl -n "${NS}" wait --for=condition=Ready "pod/pgload-${app}" --timeout=180s

  # Main DB
  if kubectl -n "${NS}" exec "pgload-${app}" -- test -f "/config/${sqlite}"; then
    echo "==> ${app}: pgloader ${sqlite} -> ${mdb}"
    kubectl -n "${NS}" exec "pgload-${app}" -- \
      pgloader --with "quote identifiers" --with "data only" \
      --with "prefetch rows = 100" --with "batch size = 1MB" \
      "/config/${sqlite}" \
      "postgresql://${PGUSER}@${PGHOST}:5432/${mdb}"
  else
    echo "WARN: missing /config/${sqlite}"
  fi

  # Log DB (optional)
  if kubectl -n "${NS}" exec "pgload-${app}" -- test -f "/config/${logs_sqlite}"; then
    echo "==> ${app}: wipe seed in ${ldb} (best-effort) + pgloader ${logs_sqlite}"
    cnpg_psql "${ldb}" 'DELETE FROM "Logs"; DELETE FROM "VersionInfo";' || true
    kubectl -n "${NS}" exec "pgload-${app}" -- \
      pgloader --with "quote identifiers" --with "data only" \
      --with "prefetch rows = 100" --with "batch size = 1MB" \
      "/config/${logs_sqlite}" \
      "postgresql://${PGUSER}@${PGHOST}:5432/${ldb}" || echo "WARN: logs migrate failed (often OK)"
  fi

  # Rename sqlite so app won't confuse operators; keep as backup
  kubectl -n "${NS}" exec "pgload-${app}" -- sh -c "
    ts=\$(date +%Y%m%d%H%M%S)
    [ -f /config/${sqlite} ] && mv /config/${sqlite} /config/${sqlite}.sqlite-bak-\$ts
    [ -f /config/${logs_sqlite} ] && mv /config/${logs_sqlite} /config/${logs_sqlite}.sqlite-bak-\$ts
    chown -R 99:100 /config
  "

  kubectl -n "${NS}" delete pod "pgload-${app}" --wait=true
  echo "==> ${app}: migrate done"
}

for app in "${APPS[@]}"; do
  migrate_one "${app}"
done

echo "==> Fix Sonarr sequences (anime + tv)"
for mdb in sonarr_anime_main sonarr_tv_main; do
  cnpg_psql "${mdb}" "$(cat <<'SQL'
DO $$ DECLARE r record; BEGIN
  FOR r IN
    SELECT quote_ident(n.nspname) AS schemaname,
           quote_ident(c.relname) AS seqname,
           quote_ident(t.relname) AS tblname,
           quote_ident(a.attname) AS colname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_depend d ON d.objid = c.oid AND d.deptype = 'a'
    JOIN pg_class t ON t.oid = d.refobjid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
    WHERE c.relkind = 'S' AND n.nspname = 'public'
  LOOP
    EXECUTE format('SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I.%I), 1))',
      r.schemaname || '.' || r.seqname, r.colname, r.schemaname, r.tblname);
  END LOOP;
END $$;
SQL
)" || echo "WARN: sequence fix for ${mdb} failed"
done

echo "==> Scale apps back up"
kubectl -n "${NS}" scale deploy/sonarr-anime deploy/sonarr-tv deploy/prowlarr --replicas=1
kubectl -n "${NS}" rollout status deploy/sonarr-anime --timeout=180s
kubectl -n "${NS}" rollout status deploy/sonarr-tv --timeout=180s
kubectl -n "${NS}" rollout status deploy/prowlarr --timeout=180s

echo "Done. Verify UIs and that config.xml has Postgres* entries."
