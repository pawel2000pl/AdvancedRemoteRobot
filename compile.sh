#!/bin/bash

./bin/arduino-cli compile --build-property compiler.cpp.extra_flag=-DSERIAL_TX_BUFFER_SIZE=256 -b pololu-a-star:avr:a-star328PB ./arduino/arduino.ino
