block_lists = {
  raw_githubusercontent_com_stevenblack_hosts_master_hosts = {
    address = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    enabled = true
    comment = "Migrated from /etc/pihole/adlists.list"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_dyndns_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/dyndns.txt"
    enabled = true
    comment = "Dynamic DNS blocking - Protects against the malicious use of dynamic DNS services!"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_fake_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/fake.txt"
    enabled = true
    comment = "Fake - Protects against internet scams, traps & fakes!"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_gambling_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/gambling.txt"
    enabled = true
    comment = "Gambling - Protects against gambling content!"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_hoster_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/hoster.txt"
    enabled = true
    comment = "Badware Hoster blocking - Protects against the malicious use of host services!"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_pro_plus_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.txt"
    enabled = true
    comment = "Multi PRO++ - Maximum protection"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_spam_tlds_adblock_t = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/spam-tlds-adblock.txt"
    enabled = true
    comment = "Most Abused TLDs - Protects against known malicious Top Level Domains! (Recommended)"
  }
  raw_githubusercontent_com_hagezi_dns_blocklists_main_adblock_tif_txt = {
    address = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt"
    enabled = true
    comment = "Threat Intelligence Feeds - Increases security significantly! (Recommended)"
  }
}

allow_lists = {}
