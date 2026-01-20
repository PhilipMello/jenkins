# Jenkins on AWS EC2 — Installation Script

This repository provides a single Bash script to install **Jenkins LTS** on a fresh **AWS EC2** instance running either:

- **Ubuntu / Debian**
- **Amazon Linux / RHEL-family** (RHEL, CentOS, Rocky, Alma, Oracle Linux, Fedora)

The script installs a supported **Java runtime**, configures the official **Jenkins LTS package repository**, installs Jenkins, enables the service, and (optionally) opens the **host firewall** for port **8080** if `ufw` or `firewalld` is active. Jenkins’ default HTTP port is **8080**. :contentReference[oaicite:0]{index=0}

---

## What the script does

### On Ubuntu/Debian
- Installs prerequisites and **OpenJDK 17 JRE**
- Adds the Jenkins **debian-stable (LTS)** APT repo and signing key
- Installs `jenkins` via `apt`
- Enables and starts the `jenkins` systemd service :contentReference[oaicite:1]{index=1}

### On Amazon Linux / RHEL-family
- Adds the Jenkins **redhat-stable (LTS)** YUM/DNF repo and signing key
- Installs **Java 17** (`java-17-openjdk`) or (if available) **Amazon Corretto 21**
- Installs `jenkins` via `yum`/`dnf`
- Enables and starts the `jenkins` systemd service :contentReference[oaicite:2]{index=2}

### Optional firewall change (host firewall only)
If a host firewall is detected and active:
- `ufw`: allows `TCP/8080`
- `firewalld`: permanently opens `8080/tcp` and reloads rules

> Important: This does **not** configure AWS Security Groups. You must open inbound access there separately.

---

## Java 17

---

## Files

- `jenkins_setup.sh` — main installation script

---

## Prerequisites (AWS EC2)

1. An EC2 instance running one of the supported Linux families (above).
2. Access to the instance via SSH with `sudo` privileges.
3. **Security Group inbound rule** allowing access to Jenkins:
   - Port **8080/TCP** from **your IP** (recommended), or from your VPN/CIDR range.

Jenkins’ Web UI is served over HTTP/HTTPS, by default on port **8080**. :contentReference[oaicite:4]{index=4}

---

## Install and run

---
## For Linux 🐧
```
wget https://raw.githubusercontent.com/PhilipMello/jenkins/refs/heads/main/jenkins_setup.sh && chmod +x jenkins_setup.sh
```

OR

```
wget https://raw.githubusercontent.com/PhilipMello/jenkins/refs/heads/main/jenkins_setup.sh && chmod +x jenkins_setup.sh && sudo mv jenkins_setup.sh /usr/bin/
```

RUN:
```
sudo ./jenkins_setup.sh
```

## After installation:

- Jenkins runs as a systemd service named `jenkins`
- Verify status:
```bash
sudo systemctl status jenkins --no-pager
```

## Access Jenkins

### Open in a browser:
```bash
http://localhost:8080
```
## Unlock Jenkins (initial admin password)
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
`Note:` This is the standard path used by Jenkins’ initial setup wizard.

### Configuration
Environment variables

The script supports:
- JENKINS_PORT (default: 8080)
`Note:` JENKINS_PORT in this script is used to open the host firewall port (ufw/firewalld). It does not reconfigure the Jenkins service port by itself. Jenkins defaults to port 8080.

Example:
```bash
sudo JENKINS_PORT=8080 ./jenkins_setup.sh
```

Changing Jenkins port (optional)

If you need Jenkins to listen on a different port because 8080 is in use, Jenkins documents using a systemd override with `JENKINS_PORT`.

Example (change to 8081):
```bash
sudo systemctl edit jenkins
```
Add:
```ìni
[Service]
Environment="JENKINS_PORT=8081"
```
Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

### Security recommendations (production)

- Do not expose port 8080 to the public Internet (0.0.0.0/0) unless you have a strong reason and compensating controls.
- Prefer a reverse proxy (Nginx/Apache) with TLS on 443 and restrict 8080 to localhost or a private subnet.
- Keep the instance patched and limit SSH access.

Jenkins’ Web UI is a network-exposed service (default 8080), so treat it like any other admin surface.

### Troubleshooting
Jenkins service won’t start

1. Check logs:
```bash
sudo journalctl -u jenkins -n 200 --no-pager
```

2. Confirm Java version:
```bash
java -version
```
3. Port conflict: Jenkins notes how to change the listening port if 8080 is in use.
- Can’t reach Jenkins from your browser
  - Confirm Jenkins is listening:
```bash
sudo ss -lntp | grep 8080 || true
```

### Common service commands

Check status:
```bash
sudo systemctl status jenkins --no-pager
```

Restart:
```bash
sudo systemctl restart jenkins
```

Stop / start:
```bash
sudo systemctl stop jenkins
sudo systemctl start jenkins
```

View recent logs:
```bash
sudo journalctl -u jenkins -n 200 --no-pager
```

Jenkins provides guidance on managing systemd services and overrides.

Confirm Jenkins is listening:
```bash
sudo ss -lntp | grep 8080 || true
```
