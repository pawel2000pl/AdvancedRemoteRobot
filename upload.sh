#!/bin/bash

sudo echo Granted sudo privileges

sudo gpio mode 1 out
sudo gpio write 1 0
(
		sleep 15s
		sudo gpio write 1 1
) &


echo Uploading...
./bin/arduino-cli upload -b pololu-a-star:avr:a-star328PB ./arduino/arduino.ino -p /dev/ttyACM* 2>&1 | (
	head -n 2
	sleep 3.9s
	sudo gpio write 1 1
	cat
)
