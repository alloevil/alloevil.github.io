#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

readonly SCRIPT_NAME="$(basename "$0")"
readonly INSTALLER_URL="https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh"
readonly XRAY_BIN="/usr/local/bin/xray"
readonly XRAY_CONFIG="/usr/local/etc/xray/config.json"
readonly CLIENT_INFO="/root/xray-client-info.txt"

SERVER_ADDRESS=""
XRAY_PORT="443"
REALITY_TARGET="www.apple.com"
ENABLE_BBR="1"
FORCE_RECONFIGURE="0"

INSTALLER_FILE=""
NEW_CONFIG=""

log() {
  printf '[%s] %s\n' "$1" "$2"
}

info() {
  log INFO "$1"
}

warn() {
  log WARN "$1" >&2
}

die() {
  log ERROR "$1" >&2
  exit 1
}

cleanup() {
  if [[ -n "$INSTALLER_FILE" && -f "$INSTALLER_FILE" ]]; then
    rm -f -- "$INSTALLER_FILE"
  fi
  if [[ -n "$NEW_CONFIG" && -f "$NEW_CONFIG" ]]; then
    rm -f -- "$NEW_CONFIG"
  fi
}

on_error() {
  local exit_code=$?
  warn "Deployment stopped at line ${BASH_LINENO[0]} (exit ${exit_code})."
  exit "$exit_code"
}

trap cleanup EXIT
trap on_error ERR

usage() {
  cat <<USAGE
Usage:
  sudo bash ${SCRIPT_NAME} --address <IPv4-or-hostname> [options]

Required:
  --address <value>   Public IPv4 address or hostname used by clients.

Options:
  --port <number>     Xray listen port (default: 443).
  --target <domain>   REALITY target and SNI (default: www.apple.com).
  --no-bbr            Do not configure BBR + fq.
  --force             Back up and replace an existing Xray configuration.
  -h, --help          Show this help message.

Examples:
  sudo bash ${SCRIPT_NAME} --address 203.0.113.10
  sudo bash ${SCRIPT_NAME} --address proxy.example.com --target www.apple.com

Important:
  * This script generates new UUID/REALITY credentials on every successful run.
  * Existing configurations are never replaced unless --force is provided.
  * The script does not change SSH, UFW, cloud security groups, or provider rules.
  * IPv6 literals are not supported by this version of the script.
USAGE
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --address)
        (($# >= 2)) || die "--address requires a value"
        SERVER_ADDRESS="$2"
        shift 2
        ;;
      --port)
        (($# >= 2)) || die "--port requires a value"
        XRAY_PORT="$2"
        shift 2
        ;;
      --target)
        (($# >= 2)) || die "--target requires a value"
        REALITY_TARGET="$2"
        shift 2
        ;;
      --no-bbr)
        ENABLE_BBR="0"
        shift
        ;;
      --force)
        FORCE_RECONFIGURE="1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

validate_inputs() {
  [[ $EUID -eq 0 ]] || die "Run this script as root (for example, with sudo)."
  [[ -n "$SERVER_ADDRESS" ]] || die "--address is required"

  if [[ ! "$SERVER_ADDRESS" =~ ^[A-Za-z0-9.-]+$ ]]; then
    die "--address must be an IPv4 address or DNS hostname"
  fi
  if [[ ! "$REALITY_TARGET" =~ ^[A-Za-z0-9.-]+$ ]]; then
    die "--target must be a DNS hostname without scheme or port"
  fi
  if [[ ! "$XRAY_PORT" =~ ^[0-9]+$ ]] || ((XRAY_PORT < 1 || XRAY_PORT > 65535)); then
    die "--port must be an integer between 1 and 65535"
  fi

  for command_name in curl openssl awk grep sed ss systemctl journalctl mktemp install timeout cp mv chmod chown date id; do
    require_command "$command_name"
  done
}

check_existing_config() {
  if [[ -s "$XRAY_CONFIG" && "$FORCE_RECONFIGURE" != "1" ]]; then
    die "Existing configuration found at ${XRAY_CONFIG}. Re-run with --force only if credential rotation is intended."
  fi
}

check_port() {
  local listeners
  listeners="$(ss -H -ltnp "sport = :${XRAY_PORT}" 2>/dev/null || true)"
  if [[ -n "$listeners" && "$listeners" != *xray* ]]; then
    warn "Port ${XRAY_PORT} is already in use:"
    printf '%s\n' "$listeners" >&2
    die "Refusing to replace a non-Xray listener"
  fi
}

check_reality_target() {
  info "Checking TLS 1.3 target ${REALITY_TARGET}:443"
  local output
  output="$(
    timeout 15 openssl s_client \
      -connect "${REALITY_TARGET}:443" \
      -servername "$REALITY_TARGET" \
      -verify_return_error \
      -tls1_3 </dev/null 2>&1 || true
  )"

  if [[ "$output" != *"Verify return code: 0 (ok)"* ]]; then
    die "REALITY target failed TLS certificate verification"
  fi
}

install_xray() {
  INSTALLER_FILE="$(mktemp /tmp/xray-install.XXXXXX.sh)"
  info "Downloading the official installer from XTLS/Xray-install"
  curl -fsSL --retry 3 --output "$INSTALLER_FILE" "$INSTALLER_URL"
  bash -n "$INSTALLER_FILE"

  if [[ -n "${XRAY_INSTALLER_SHA256:-}" ]]; then
    require_command sha256sum
    local actual_sha256
    actual_sha256="$(sha256sum "$INSTALLER_FILE" | awk '{print $1}')"
    [[ "$actual_sha256" == "$XRAY_INSTALLER_SHA256" ]] \
      || die "Installer SHA-256 does not match XRAY_INSTALLER_SHA256"
  else
    warn "XRAY_INSTALLER_SHA256 is not set; source and syntax were checked, but the installer was not pinned to a checksum."
  fi

  bash "$INSTALLER_FILE" install
  [[ -x "$XRAY_BIN" ]] || die "Xray was not installed at ${XRAY_BIN}"
  info "$($XRAY_BIN version | sed -n '1p')"
}

backup_existing_files() {
  local timestamp
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

  if [[ -e "$XRAY_CONFIG" ]]; then
    cp -a -- "$XRAY_CONFIG" "${XRAY_CONFIG}.backup.${timestamp}"
    info "Backed up the old Xray configuration"
  fi
  if [[ -e "$CLIENT_INFO" ]]; then
    cp -a -- "$CLIENT_INFO" "${CLIENT_INFO}.backup.${timestamp}"
    info "Backed up the old client information"
  fi
}

generate_credentials() {
  UUID="$($XRAY_BIN uuid)"

  local key_output
  key_output="$($XRAY_BIN x25519)"
  PRIVATE_KEY="$(printf '%s\n' "$key_output" | awk -F': ' '$1 == "PrivateKey" || $1 == "Private key" {print $2; exit}')"
  PUBLIC_KEY="$(printf '%s\n' "$key_output" | awk -F': ' '$1 ~ /PublicKey/ || $1 == "Public key" {print $2; exit}')"
  SHORT_ID="$(openssl rand -hex 8)"

  [[ -n "$UUID" ]] || die "Failed to generate UUID"
  [[ -n "$PRIVATE_KEY" ]] || die "Failed to parse REALITY private key"
  [[ -n "$PUBLIC_KEY" ]] || die "Failed to parse REALITY public key"
  [[ "$SHORT_ID" =~ ^[0-9a-f]{16}$ ]] || die "Failed to generate Short ID"
}

write_and_validate_config() {
  install -d -m 0755 "$(dirname "$XRAY_CONFIG")"
  NEW_CONFIG="$(mktemp --suffix=.json "$(dirname "$XRAY_CONFIG")/config.new.XXXXXX")"

  cat >"$NEW_CONFIG" <<JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      "listen": "0.0.0.0",
      "port": ${XRAY_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "xtls-rprx-vision",
            "email": "personal"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "target": "${REALITY_TARGET}:443",
          "xver": 0,
          "serverNames": [
            "${REALITY_TARGET}"
          ],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [
            "${SHORT_ID}"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "blocked",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
JSON

  local service_group="nogroup"
  if id nobody >/dev/null 2>&1; then
    service_group="$(id -gn nobody)"
  fi
  chown root:"$service_group" "$NEW_CONFIG"
  chmod 0640 "$NEW_CONFIG"

  info "Validating the candidate Xray configuration"
  "$XRAY_BIN" run -test -config "$NEW_CONFIG"
  mv -f -- "$NEW_CONFIG" "$XRAY_CONFIG"
  NEW_CONFIG=""
}

write_client_info() {
  CLIENT_URI="vless://${UUID}@${SERVER_ADDRESS}:${XRAY_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_TARGET}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#Xray-Reality"

  cat >"$CLIENT_INFO" <<INFO
Protocol: VLESS
Address: ${SERVER_ADDRESS}
Port: ${XRAY_PORT}
UUID: ${UUID}
Flow: xtls-rprx-vision
Transport: tcp
Security: reality
SNI: ${REALITY_TARGET}
Fingerprint: chrome
Public key: ${PUBLIC_KEY}
Short ID: ${SHORT_ID}

URI:
${CLIENT_URI}
INFO
  chmod 0600 "$CLIENT_INFO"
}

configure_bbr() {
  [[ "$ENABLE_BBR" == "1" ]] || {
    info "Skipping BBR configuration"
    return
  }

  if ! modinfo tcp_bbr >/dev/null 2>&1; then
    warn "tcp_bbr is unavailable on this kernel; skipping BBR"
    return
  fi

  local conflicts
  conflicts="$(
    grep -RHE '^[[:space:]]*net\.(ipv4\.tcp_congestion_control|core\.default_qdisc)[[:space:]]*=' \
      /etc/sysctl.conf /etc/sysctl.d 2>/dev/null \
      | grep -v '^/etc/sysctl.d/99-xray-network.conf:' || true
  )"
  if [[ -n "$conflicts" ]]; then
    warn "Existing congestion-control settings were found; skipping persistent BBR changes:"
    printf '%s\n' "$conflicts" >&2
    return
  fi

  if [[ -e /etc/modules-load.d/xray-bbr.conf ]] \
    && [[ "$(tr -d '[:space:]' </etc/modules-load.d/xray-bbr.conf)" != "tcp_bbr" ]]; then
    warn "Existing /etc/modules-load.d/xray-bbr.conf is not owned by this layout; skipping BBR"
    return
  fi

  if [[ -e /etc/sysctl.d/99-xray-network.conf ]] \
    && ! grep -q 'net.ipv4.tcp_congestion_control = bbr' /etc/sysctl.d/99-xray-network.conf; then
    warn "Existing /etc/sysctl.d/99-xray-network.conf has different settings; skipping BBR"
    return
  fi

  if ! modprobe tcp_bbr; then
    warn "Failed to load tcp_bbr; skipping BBR"
    return
  fi

  if ! sysctl -w net.core.default_qdisc=fq >/dev/null \
    || ! sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null; then
    warn "The running kernel rejected BBR settings; skipping persistent BBR files"
    return
  fi

  printf '%s\n' 'tcp_bbr' \
    | install -m 0644 /dev/stdin /etc/modules-load.d/xray-bbr.conf
  printf '%s\n' \
    '# Xray TCP transport tuning' \
    'net.core.default_qdisc = fq' \
    'net.ipv4.tcp_congestion_control = bbr' \
    | install -m 0644 /dev/stdin /etc/sysctl.d/99-xray-network.conf

  info "Enabled BBR + fq for new TCP connections"
}

start_and_verify_service() {
  systemctl daemon-reload
  systemctl enable xray >/dev/null
  systemctl restart xray
  sleep 2

  systemctl is-active --quiet xray || {
    journalctl -u xray -n 50 --no-pager >&2 || true
    die "Xray did not become active"
  }

  ss -H -ltnp "sport = :${XRAY_PORT}" | grep -q xray \
    || die "Xray is active but is not listening on TCP ${XRAY_PORT}"
}

print_summary() {
  cat <<SUMMARY

Deployment completed successfully.

Server:       ${SERVER_ADDRESS}:${XRAY_PORT}
Protocol:     VLESS + REALITY + XTLS Vision
REALITY SNI:  ${REALITY_TARGET}
Client file:  ${CLIENT_INFO}
Xray config:  ${XRAY_CONFIG}

Client URI (keep it private):
${CLIENT_URI}

Next checks:
  1. Allow TCP ${XRAY_PORT} in the cloud firewall/security group.
  2. Import the URI into a compatible client.
  3. Test the client before disabling SSH password authentication.
SUMMARY
}

main() {
  parse_args "$@"
  validate_inputs
  check_existing_config
  check_port
  check_reality_target
  install_xray
  backup_existing_files
  generate_credentials
  write_and_validate_config
  configure_bbr
  start_and_verify_service
  write_client_info
  print_summary
}

main "$@"
