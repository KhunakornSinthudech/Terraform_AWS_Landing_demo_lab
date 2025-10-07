# debug on webapp
sudo systemctl status webapp
sudo tail -n 100 /var/log/webapp.log
sudo ss -lntp | grep :8080 || true
curl -sS http://127.0.0.1:8080/healthz

# 1) ดู service file + env ที่ใส่ให้
sudo systemctl cat webapp

# 2) ดูบันทึกล่าสุดของ service
sudo journalctl -u webapp -b --no-pager | tail -n 100

# 3) ถ้ามีไฟล์ log ตาม unit
sudo tail -n 100 /var/log/webapp.log

# 4) มีไฟล์และสิทธิ์ครบไหม
ls -l /opt/webapp/
head -n 5 /opt/webapp/start_webapp.sh
command -v aws || which aws
command -v python3 || which python3



sudo systemctl daemon-reload
sudo systemctl reset-failed webapp
sudo systemctl start webapp
sudo systemctl status webapp



# Test Cloudwatch agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status systemctl is-active amazon-cloudwatch-agent



