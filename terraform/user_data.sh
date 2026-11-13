#!/bin/bash
# Runs once at first boot: install Docker Engine + Compose plugin and prepare the app folder.
set -eux
apt-get update -y
apt-get install -y ca-certificates curl
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
usermod -aG docker ubuntu
mkdir -p /home/ubuntu/taskops
chown ubuntu:ubuntu /home/ubuntu/taskops
