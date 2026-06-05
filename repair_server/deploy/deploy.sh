#!/bin/bash
# 部署脚本 - 家政维修服务平台

set -e

echo "=== Building repair server ==="
cd "$(dirname "$0")/.."
go build -o repair .

echo "=== Deploying ==="
sudo mkdir -p /opt/repair/data/uploads
sudo cp repair /opt/repair/
sudo cp deploy/repair.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable repair
sudo systemctl restart repair

echo "=== Deployment complete ==="
echo "Server: http://localhost:8080"
echo "Status: systemctl status repair"
echo "Logs:   journalctl -u repair -f"
