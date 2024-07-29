#!/bin/bash

cp init.sh /root/init_gpio.sh

echo \
"[Unit]
Description=GPIO and fan initialization
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=no
RestartSec=1
User=root
ExecStart=/root/init_gpio.sh

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/init_gpio.service

systemctl enable init_gpio.service
systemctl start init_gpio.service



echo \
"[Unit]
Description=Robot network services
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$1
ExecStart=$PWD/start.sh

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/robot-services.service

systemctl enable robot-services.service
systemctl start robot-services.service

