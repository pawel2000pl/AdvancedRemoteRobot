#pragma once

using int16 = signed short int;

template<typename T, typename U> constexpr int offsetOf(U T::*member)
{
    return (char*)&((T*)nullptr->*member) - (char*)nullptr;
}

// BEGIN REGISTERS DEFINITION
struct Registers {

  int16 ping = 3000;

  int16 leftEngine = 0;
  int16 rightEngine = 0;

  int16 battery = 0; //mV
  int16 beep = 0;

  int16 led = 0;

  // mm/s
  int16 leftVelocity = 0;
  int16 rightVelocity = 0;

  int16 cameraX = 0;
  int16 cameraY = 0;

  int16 stopTimeout = 3000;
  int16 emergencyStop = 0;
  int16 sensorsStates[24] = {0};
  int16 sensorsEventStop[24] = {0}; // negative - stop when lower, positive - stop when higher, 0 - deactivated

};
// END REGISTERS DEFINITION


// BEGIN LIST OF WRITE REGISTERS
const int WRITE_REGISTERS[] = {
  offsetOf(&Registers::ping)/2,
  offsetOf(&Registers::leftEngine)/2,
  offsetOf(&Registers::rightEngine)/2,
  offsetOf(&Registers::beep)/2,
  offsetOf(&Registers::led)/2,
  offsetOf(&Registers::sensorsEventStop)/2,
  offsetOf(&Registers::sensorsEventStop)/2+1,
  offsetOf(&Registers::sensorsEventStop)/2+2,
  offsetOf(&Registers::sensorsEventStop)/2+3,
  offsetOf(&Registers::sensorsEventStop)/2+4,
  offsetOf(&Registers::sensorsEventStop)/2+5,
  offsetOf(&Registers::sensorsEventStop)/2+6,
  offsetOf(&Registers::sensorsEventStop)/2+7,
  offsetOf(&Registers::sensorsEventStop)/2+8,
  offsetOf(&Registers::sensorsEventStop)/2+9,
  offsetOf(&Registers::sensorsEventStop)/2+10,
  offsetOf(&Registers::sensorsEventStop)/2+11,
  offsetOf(&Registers::sensorsEventStop)/2+12,
  offsetOf(&Registers::sensorsEventStop)/2+13,
  offsetOf(&Registers::sensorsEventStop)/2+14,
  offsetOf(&Registers::sensorsEventStop)/2+15,
  offsetOf(&Registers::sensorsEventStop)/2+16,
  offsetOf(&Registers::sensorsEventStop)/2+17,
  offsetOf(&Registers::sensorsEventStop)/2+18,
  offsetOf(&Registers::sensorsEventStop)/2+19,
  offsetOf(&Registers::sensorsEventStop)/2+20,
  offsetOf(&Registers::sensorsEventStop)/2+21,
  offsetOf(&Registers::sensorsEventStop)/2+22,
  offsetOf(&Registers::sensorsEventStop)/2+23,
  -1
};
// END LIST OF WRITE REGISTERS


// BEGIN LIST OF READ REGISTERS
const int READ_REGISTERS[] = {
  offsetOf(&Registers::battery)/2,
  offsetOf(&Registers::leftVelocity)/2,
  offsetOf(&Registers::rightVelocity)/2,
  offsetOf(&Registers::stopTimeout)/2,
  offsetOf(&Registers::emergencyStop)/2,
  offsetOf(&Registers::sensorsStates)/2,
  offsetOf(&Registers::sensorsStates)/2+1,
  offsetOf(&Registers::sensorsStates)/2+2,
  offsetOf(&Registers::sensorsStates)/2+3,
  offsetOf(&Registers::sensorsStates)/2+4,
  offsetOf(&Registers::sensorsStates)/2+5,
  offsetOf(&Registers::sensorsStates)/2+6,
  offsetOf(&Registers::sensorsStates)/2+7,
  offsetOf(&Registers::sensorsStates)/2+8,
  offsetOf(&Registers::sensorsStates)/2+9,
  offsetOf(&Registers::sensorsStates)/2+10,
  offsetOf(&Registers::sensorsStates)/2+11,
  offsetOf(&Registers::sensorsStates)/2+12,
  offsetOf(&Registers::sensorsStates)/2+13,
  offsetOf(&Registers::sensorsStates)/2+14,
  offsetOf(&Registers::sensorsStates)/2+15,
  offsetOf(&Registers::sensorsStates)/2+16,
  offsetOf(&Registers::sensorsStates)/2+17,
  offsetOf(&Registers::sensorsStates)/2+18,
  offsetOf(&Registers::sensorsStates)/2+19,
  offsetOf(&Registers::sensorsStates)/2+20,
  offsetOf(&Registers::sensorsStates)/2+21,
  offsetOf(&Registers::sensorsStates)/2+22,
  offsetOf(&Registers::sensorsStates)/2+23,
  -1
};
// END LIST OF READ REGISTERS

