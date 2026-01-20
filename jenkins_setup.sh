#!/usr/bin/env bash
set -euo pipefail

JENKINS_PORT="${JENKINS_PORT:-8080}"

log() { printf "\n[setup-jenkins] %s\n" "$*"; }
die() { printf "\n[setup-jenkins] ERROR: %s\n" "$*" >&2; exit 1; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Run as root (e.g., sudo $0)"
  fi
}

detect_os() {
  if [[ ! -f /etc/os-release ]]; then
    die "/etc/os-release not found; cannot detect OS"
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_LIKE="${ID_LIKE:-}"
}

install_jenkins_debian_like() {
  log "Detected Debian/Ubuntu. Installing Java (OpenJDK 21) and prerequisites..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg fontconfig openjdk-21-jre

  log "Adding Jenkins LTS apt repository..."
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL "https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key" \
    -o /etc/apt/keyrings/jenkins-keyring.asc
  chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

  cat >/etc/apt/sources.list.d/jenkins.list <<EOF
deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/
EOF

  apt-get update -y
  log "Installing Jenkins..."
  apt-get install -y jenkins

  log "Enabling and starting Jenkins..."
  systemctl daemon-reload
  systemctl enable --now jenkins
}

install_jenkins_redhat_like() {
  local pm="yum"
  if command -v dnf >/dev/null 2>&1; then pm="dnf"; fi

  log "Detected RHEL/Amazon Linux family. Updating system..."
  # Some distros prefer upgrade, some prefer update; try upgrade first.
  "$pm" -y upgrade || "$pm" -y update

  log "Adding Jenkins LTS yum/dnf repository..."
  curl -fsSL -o /etc/yum.repos.d/jenkins.repo \
    "https://pkg.jenkins.io/redhat-stable/jenkins.repo"
  rpm --import "https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key"

  log "Installing Java 21 and dependencies..."
  # Prefer Amazon Corretto on Amazon Linux if available; otherwise OpenJDK.
  if "$pm" -y install fontconfig java-21-amazon-corretto >/dev/null 2>&1; then
    log "Installed Amazon Corretto 21."
  else
    "$pm" -y install fontconfig java-21-openjdk
    log "Installed OpenJDK 21."
  fi

  log "Installing Jenkins..."
  "$pm" -y install jenkins

  log "Enabling and starting Jenkins..."
  systemctl daemon-reload
  systemctl enable --now jenkins
}

open_firewall_if_present() {
  log "Checking host firewall (optional)..."
  if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -qi "Status: active"; then
      log "ufw is active; allowing TCP/${JENKINS_PORT}..."
      ufw allow "${JENKINS_PORT}/tcp" >/dev/null
    else
      log "ufw installed but not active; no changes made."
    fi
  elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state >/dev/null 2>&1; then
      log "firewalld is active; allowing TCP/${JENKINS_PORT}..."
      firewall-cmd --permanent --add-port="${JENKINS_PORT}/tcp" >/dev/null
      firewall-cmd --reload >/dev/null
    else
      log "firewalld installed but not running; no changes made."
    fi
  else
    log "No ufw/firewalld detected; no host firewall rules applied."
  fi
}

print_next_steps() {
  local public_hint="http://<EC2_PUBLIC_DNS>:${JENKINS_PORT}"
  log "Jenkins installation complete."

  echo
  echo "Next steps (AWS EC2):"
  echo "1) In your EC2 Security Group, allow inbound TCP/${JENKINS_PORT} from your IP (recommended),"
  echo "   or from your corporate/VPN CIDR. Do NOT leave it open to 0.0.0.0/0 unless you understand the risk."
  echo "2) Open: ${public_hint}"
  echo "3) Unlock Jenkins with the initial admin password:"
  echo "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  echo
  echo "Service status:"
  echo "  sudo systemctl status jenkins --no-pager"
}

main() {
  require_root
  detect_os

  case "${OS_ID}" in
    ubuntu|debian)
      install_jenkins_debian_like
      ;;
    amzn|amazon|rhel|fedora|centos|rocky|almalinux|ol)
      install_jenkins_redhat_like
      ;;
    *)
      if [[ "${OS_LIKE}" == *"debian"* || "${OS_LIKE}" == *"ubuntu"* ]]; then
        install_jenkins_debian_like
      elif [[ "${OS_LIKE}" == *"rhel"* || "${OS_LIKE}" == *"fedora"* || "${OS_LIKE}" == *"centos"* ]]; then
        install_jenkins_redhat_like
      else
        die "Unsupported OS: ID='${OS_ID}' ID_LIKE='${OS_LIKE}'"
      fi
      ;;
  esac

  open_firewall_if_present
  print_next_steps
}

main "$@"
