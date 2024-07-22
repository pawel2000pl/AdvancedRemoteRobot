#!/bin/bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y curl python3 python3-pip python3-serial python3-cherrypy3 python3-ws4py odroid-wiringpi libjpeg8-dev
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

./bin/arduino-cli config init
./bin/arduino-cli config add board_manager.additional_urls https://files.pololu.com/arduino/package_pololu_index.json
./bin/arduino-cli core update-index
./bin/arduino-cli board listall
./bin/arduino-cli core install arduino:avr
./bin/arduino-cli core install pololu-a-star:avr




