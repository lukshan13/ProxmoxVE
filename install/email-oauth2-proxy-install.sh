#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: lukshan13
# License: MIT | https://github.com/lukshan13/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/simonrob/email-oauth2-proxy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES
# =============================================================================

msg_info "Installing Dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip \
  python3-venv
msg_ok "Installed Dependencies"

# =============================================================================
# APPLICATION INSTALL (PyPI - no GitHub release)
# =============================================================================

msg_info "Installing Email OAuth2 Proxy (PyPI)"
$STD pip3 install --break-system-packages emailproxy
msg_ok "Installed Email OAuth2 Proxy"

# =============================================================================
# CONFIGURATION
# =============================================================================

msg_info "Configuring Email OAuth2 Proxy"
mkdir -p /etc/emailproxy
CONFIG_FILE="/etc/emailproxy/emailproxy.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/simonrob/email-oauth2-proxy/main/emailproxy.config" -o "$CONFIG_FILE"
fi

sed -i 's/^local_address = 127\.0\.0\.1$/local_address = 0.0.0.0/g' "$CONFIG_FILE" 2>/dev/null || true
msg_ok "Configured Email OAuth2 Proxy"

# =============================================================================
# SYSTEMD SERVICE
# =============================================================================

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/emailproxy.service
[Unit]
Description=Email OAuth 2.0 Proxy - IMAP/POP/SMTP OAuth2 proxy
Documentation=https://github.com/simonrob/email-oauth2-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/emailproxy
ExecStart=/usr/bin/python3 -m emailproxy --no-gui --config-file /etc/emailproxy/emailproxy.config
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now emailproxy
msg_ok "Created Service"

# =============================================================================
# VERSION TRACKING
# =============================================================================

INSTALLED_VERSION=$(python3 -c "import emailproxy; print(getattr(emailproxy, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
echo "${INSTALLED_VERSION}" >/opt/emailproxy_version.txt 2>/dev/null || true

motd_ssh
customize
cleanup_lxc
