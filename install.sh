#!/bin/bash
set -e

sudo apt update
sudo apt full-upgrade -y
sudo apt install -y curl cmake python3 python3-pip odroid-wiringpi libjpeg8-dev sqlite3

python3 -m pip install -U pip
python3 -m pip install -U setuptools
python3 -m pip install -U setuptools_scm
python3 -m pip install pyserial cherrypy ws4py cython numpy

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
./bin/arduino-cli config init
./bin/arduino-cli config add board_manager.additional_urls https://files.pololu.com/arduino/package_pololu_index.json
./bin/arduino-cli core update-index
./bin/arduino-cli board listall
./bin/arduino-cli core install arduino:avr
./bin/arduino-cli core install pololu-a-star:avr

sudo apt install -y nginx
sudo rm -rf /etc/nginx/cert
sudo cp -r cert /etc/nginx/cert
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx/sites-available/*
sudo cp nginx.conf /etc/nginx/sites-available/robot.conf
sudo ln -s /etc/nginx/sites-available/robot.conf /etc/nginx/sites-enabled/robot.conf 
sudo systemctl enable nginx
sudo systemctl restart nginx

chmod +x *.sh
sudo ./install_services.sh $USER
cd server/src
python3 configuration.py
cd ../..
