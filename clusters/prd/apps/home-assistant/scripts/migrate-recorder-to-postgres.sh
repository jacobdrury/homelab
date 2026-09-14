#!/usr/bin/env bash
# Migrate Home Assistant recorder from SQLite (config PVC) → home-assistant-pg (CNPG).
# Pattern: boot once on empty PG (schema) → stop → wipe seed rows → pgloader data-only → fix sequences → start.
#
# Usage (from repo root):
#   source connect/env.sh
#   ./clusters/prd/apps/home-assistant/scripts/migrate-recorder-to-postgres.sh
set -eo pipefail

NS=home-assistant
PGLOADER_IMAGE=ghcr.io/roxedus/pgloader@sha256:1a7a86ad56623c00ee714ee4969913ed5c6f59ac9785073e2ffd1bea9cc54d31
PGHOST=home-assistant-pg-rw.home-assistant.svc.cluster.local
PGUSER=$(kubectl -n "${NS}" get secret home-assistant-pg-owner -o jsonpath='{.data.username}' | base64 -d)
PGPASS=$(kubectl -n "${NS}" get secret home-assistant-pg-owner -o jsonpath='{.data.password}' | base64 -d)
PVC=home-assistant-config
SQLITE=home-assistant_v2.db
DB=homeassistant

cnpg_psql() {
  local sql="$1"
  kubectl -n "${NS}" exec -i home-assistant-pg-1 -c postgres -- \
    env PGPASSWORD="${PGPASS}" psql -h 127.0.0.1 -U "${PGUSER}" -d "${DB}" -v ON_ERROR_STOP=1 <<< "${sql}"
}

echo "==> Waiting for home-assistant-pg healthy"
kubectl -n "${NS}" wait --for=condition=Ready cluster/home-assistant-pg --timeout=300s

echo "==> Schema bootstrap: start HA once against empty Postgres"
kubectl -n "${NS}" scale deploy/home-assistant --replicas=1
kubectl -n "${NS}" rollout status deploy/home-assistant --timeout=300s
echo "    waiting for recorder schema (~45s)"
sleep 45

echo "==> Scale down for pgloader"
kubectl -n "${NS}" scale deploy/home-assistant --replicas=0
kubectl -n "${NS}" wait --for=delete pod -l app.kubernetes.io/name=home-assistant --timeout=180s || true

echo "==> Wipe PG seed rows (best-effort)"
cnpg_psql "$(cat <<'SQL'
DO $$ DECLARE r record; BEGIN
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
    EXECUTE format('TRUNCATE TABLE %I CASCADE', r.tablename);
  END LOOP;
END $$;
SQL
)" || true

echo "==> pgloader ${SQLITE} -> ${DB}"
kubectl -n "${NS}" delete pod pgload-home-assistant --ignore-not-found --wait=true
kubectl -n "${NS}" run pgload-home-assistant \
  --image="${PGLOADER_IMAGE}" \
  --restart=Never \
  --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "pgloader",
      "image": "${PGLOADER_IMAGE}",
      "command": ["sleep", "3600"],
      "env": [{"name": "PGPASSWORD", "value": "${PGPASS}"}],
      "volumeMounts": [
        {"name": "cfg", "mountPath": "/config"},
        {"name": "work", "mountPath": "/work"}
      ]
    }],
    "volumes": [
      {"name": "cfg", "persistentVolumeClaim": {"claimName": "${PVC}"}},
      {"name": "work", "emptyDir": {}}
    ],
    "restartPolicy": "Never"
  }
}
EOF
)"
kubectl -n "${NS}" wait --for=condition=Ready pod/pgload-home-assistant --timeout=180s

if ! kubectl -n "${NS}" exec pgload-home-assistant -- test -f "/config/${SQLITE}"; then
  echo "ERROR: missing /config/${SQLITE} — copy config from HA OS first"
  kubectl -n "${NS}" delete pod pgload-home-assistant --wait=true || true
  exit 1
fi

kubectl -n "${NS}" exec pgload-home-assistant -- \
  pgloader --with "quote identifiers" --with "data only" \
  --with "prefetch rows = 100" --with "batch size = 1MB" \
  "/config/${SQLITE}" \
  "postgresql://${PGUSER}@${PGHOST}:5432/${DB}"

kubectl -n "${NS}" exec pgload-home-assistant -- sh -c "
  ts=\$(date +%Y%m%d%H%M%S)
  mv /config/${SQLITE} /config/${SQLITE}.sqlite-bak-\$ts
  rm -f /config/${SQLITE}-shm /config/${SQLITE}-wal 2>/dev/null || true
"
kubectl -n "${NS}" delete pod pgload-home-assistant --wait=true

echo "==> Fix sequences after data-only load"
# pgloader data-only leaves serials stale; two-arg setval(max) with is_called=true.
# Do not quote_ident then re-stringify for setval — that no-ops / misses sequences.
cnpg_psql "$(cat <<'SQL'
DO $$
DECLARE
  r record;
  max_id bigint;
BEGIN
  FOR r IN
    SELECT
      n.nspname AS schemaname,
      c.relname AS tablename,
      a.attname AS colname,
      pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) AS seqname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) IS NOT NULL
  LOOP
    EXECUTE format(
      'SELECT coalesce(max(%I), 0) FROM %I.%I',
      r.colname, r.schemaname, r.tablename
    ) INTO max_id;
    PERFORM setval(r.seqname, greatest(max_id, 1), max_id > 0);
  END LOOP;
END $$;
SQL
)"

echo "==> Scale home-assistant back up"
kubectl -n "${NS}" scale deploy/home-assistant --replicas=1
kubectl -n "${NS}" rollout status deploy/home-assistant --timeout=300s

echo "Done. Verify UI + history graphs + Authentik SSO at https://homeassistant.lab.jacobdrury.com"
