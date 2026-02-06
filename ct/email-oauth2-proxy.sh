#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/lukshan13/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: lukshan13
# License: MIT | https://github.com/lukshan13/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/simonrob/email-oauth2-proxy

APP="Email-OAuth2-Proxy"
var_tags="${var_tags:-email;oauth2;proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/emailproxy.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP} LXC"
  $STD apt-get update
  $STD apt-get -o Dpkg::Options::="--force-confold" -y dist-upgrade
  msg_ok "Updated ${APP} LXC"

  msg_info "Updating Email OAuth2 Proxy (pip)"
  $STD pip3 install --break-system-packages -U emailproxy
  msg_ok "Updated Email OAuth2 Proxy"

  msg_info "Restarting Service"
  $STD systemctl restart emailproxy
  msg_ok "Restarted Service"
  msg_ok "Updated successfully!"
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Configure your email client to use this proxy:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}IMAP: ${IP}:1993  |  POP: ${IP}:1995  |  SMTP: ${IP}:1587${CL}"
echo -e "${INFO}${YW} Edit config and add OAuth client credentials: ${BGN}/etc/emailproxy/emailproxy.config${CL}"
echo -e "${INFO}${YW} First-time auth: use menu 'Authorise account' or run with ${BGN}--external-auth${CL}"
