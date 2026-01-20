# Jenkins on AWS EC2 — Installation Script

This repository provides a single Bash script to install **Jenkins LTS** on a fresh **AWS EC2** instance running either:

- **Ubuntu / Debian**
- **Amazon Linux / RHEL-family** (RHEL, CentOS, Rocky, Alma, Oracle Linux, Fedora)

The script installs a supported **Java runtime**, configures the official **Jenkins LTS package repository**, installs Jenkins, enables the service, and (optionally) opens the **host firewall** for port **8080** if `ufw` or `firewalld` is active. Jenkins’ default HTTP port is **8080**. :contentReference[oaicite:0]{index=0}

---

## What the script does

### On Ubuntu/Debian
- Installs prerequisites and **OpenJDK 21 JRE**
- Adds the Jenkins **debian-stable (LTS)** APT repo and signing key
- Installs `jenkins` via `apt`
- Enables and starts the `jenkins` systemd service :contentReference[oaicite:1]{index=1}

### On Amazon Linux / RHEL-family
- Adds the Jenkins **redhat-stable (LTS)** YUM/DNF repo and signing key
- Installs **Java 21** (`java-21-openjdk`) or (if available) **Amazon Corretto 21**
- Installs `jenkins` via `yum`/`dnf`
- Enables and starts the `jenkins` systemd service :contentReference[oaicite:2]{index=2}

### Optional firewall change (host firewall only)
If a host firewall is detected and active:
- `ufw`: allows `TCP/8080`
- `firewalld`: permanently opens `8080/tcp` and reloads rules

> Important: This does **not** configure AWS Security Groups. You must open inbound access there separately.

---

## Why Java 21?

Jenkins supports specific Java LTS versions, and modern Jenkins releases support Java 21 (with guidance for upgrading/running on it). :contentReference[oaicite:3]{index=3}

---

## Files

- `setup-jenkins-ec2.sh` — main installation script

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
# 🔧 Git-Switch
# For Linux 🐧
```
wget https://raw.githubusercontent.com/PhilipMello/jenkins/refs/heads/main/jenkins_setup.sh && chmod +x jenkins_setup.sh
```

OR

```
wget https://raw.githubusercontent.com/PhilipMello/jenkins/refs/heads/main/jenkins_setup.sh && chmod +x jenkins_setup.sh && sudo mv jenkins_setup.sh /usr/bin/
```

RUN:
```
sudo ./setup-jenkins-ec2.sh
```
