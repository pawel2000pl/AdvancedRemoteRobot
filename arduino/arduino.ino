#include "registers.h"

#define BEEP_PIN 13
#define BATTERY_PIN 14
#define LEFT_VELOCITY 2
#define RIGHT_VELOCITY 3

#define SENSOR_SELECT_0 15
#define SENSOR_SELECT_1 16
#define SENSOR_SELECT_2 17

#define SENSOR_READ_A 18
#define SENSOR_READ_B 19
#define SENSOR_READ_C 20

#define ENGINE_RIGHT_POWER 5
#define ENGINE_LEFT_POWER 6
#define ENGINE_RIGHT_DIRECTION 7
#define ENGINE_LEFT_DIRECTION 8

#define HELLO_VALUE 185
#define SPEEDOMETER_INTERRUPS_PER_ROUND 64
#define WHEEL_LENGTH_CM 45

unsigned long long int lasCheckVelocityTime = micros();
unsigned long long int leftEngineInterrupts = 0;
unsigned long long int rightEngineInterrupts = 0;

Registers registers;


void leftEngineInterrupt() {
  leftEngineInterrupts++;
}

void rightEngineInterrupt() {
  rightEngineInterrupts++;
}


void setEnginePower(int power, int direction, int *currentPower, int *currentDirection) {
  if (direction != *currentDirection) {
    if (*currentPower)
      *currentPower = 0;
    else 
      *currentDirection = direction;
  } else 
    *currentPower = power;
}


void setEnginesPower(int16 left, int16 right) {

  static unsigned long long int lastExec = micros();
  unsigned long long int t = micros();
  if (t - lastExec < 100)
    delayMicroseconds(100 - (t - lastExec));
  lastExec = t;

  int leftPower = abs(left);
  int rightPower = abs(right);
  int leftDirection = left >= 0 ? HIGH : LOW;
  int rightDirection = right >= 0 ? HIGH : LOW;

  static int currentLeftPower = 0;
  static int currentRightPower = 0;
  static int currentLeftDirection = HIGH;
  static int currentRightDirection = HIGH;

  setEnginePower(leftPower, leftDirection, &currentLeftPower, &currentLeftDirection);
  setEnginePower(rightPower, rightDirection, &currentRightPower, &currentRightDirection);

  analogWrite(ENGINE_LEFT_POWER, currentLeftPower);
  analogWrite(ENGINE_RIGHT_POWER, currentRightPower);
  digitalWrite(ENGINE_LEFT_DIRECTION, currentLeftDirection);
  digitalWrite(ENGINE_RIGHT_DIRECTION, currentRightDirection);

}


void readHardware() {
    registers.battery = (unsigned long long)analogRead(BATTERY_PIN) * (5200l * (47l + 22l)) / (22l * 1024l);

    unsigned long long int time = micros();
    unsigned long long int dt = time - lasCheckVelocityTime;
    lasCheckVelocityTime = time;
    registers.leftVelocity = (unsigned long long)leftEngineInterrupts * (1000000 * WHEEL_LENGTH_CM) / (dt * SPEEDOMETER_INTERRUPS_PER_ROUND);
    registers.rightVelocity = (unsigned long long)rightEngineInterrupts * (1000000 * WHEEL_LENGTH_CM) / (dt * SPEEDOMETER_INTERRUPS_PER_ROUND);

    int sensor_pins[] = {SENSOR_SELECT_0, SENSOR_SELECT_1, SENSOR_SELECT_2};

    for (int i=0;i<8;i++) {
      digitalWrite(SENSOR_SELECT_0, (i & 1) ? HIGH : LOW);
      digitalWrite(SENSOR_SELECT_1, (i & 2) ? HIGH : LOW);
      digitalWrite(SENSOR_SELECT_2, (i & 4) ? HIGH : LOW);
      delay(1);
      registers.sensorsStates[i] = analogRead(SENSOR_READ_A);
      registers.sensorsStates[i+8] = analogRead(SENSOR_READ_B);
      registers.sensorsStates[i+16] = analogRead(SENSOR_READ_C);
    }

    for (int i=0;i<24;i++) {
      if (
        (registers.sensorsEventStop[i] < 0 && registers.sensorsStates[i] < -registers.sensorsEventStop[i]) ||
        (registers.sensorsEventStop[i] > 0 && registers.sensorsStates[i] > registers.sensorsEventStop[i])
      ) {
        registers.emergencyStop = millis();
        break;
      }
    }

}


void sendData(unsigned char addr, int16 value) {
  unsigned absValue = abs((int)value);
  unsigned char buf[5] = {HELLO_VALUE, addr, absValue & 255, absValue >> 8, ((unsigned)(addr + 1) * (absValue + 1)) & 255};
  Serial.write(buf, 5);
}


void sendRegisters() {
  static Registers registersState;
  int16 *registersPtr = (int16*)(&registers);
  int16 *registersStatePtr = (int16*)(&registersState);

  for ( int i = 0; READ_REGISTERS[i] >= 0; i++) {
    if (registersStatePtr[READ_REGISTERS[i]] != registersPtr[READ_REGISTERS[i]]) {
      sendData(READ_REGISTERS[i], registersPtr[READ_REGISTERS[i]]);
      registersStatePtr[READ_REGISTERS[i]] = registersPtr[READ_REGISTERS[i]];
    }
  }
}


bool recvData() {
  while (Serial.read() != HELLO_VALUE);
  unsigned char buf[4] = {0};
  Serial.readBytes(buf, 4);
  unsigned addr = buf[0];
  int16 value = (unsigned)buf[1] | ((unsigned)buf[2] << 8);
  unsigned checksum = buf[3];
  if ((((unsigned)(addr + 1) * (unsigned)(abs((int)value) + 1)) & 255) == checksum && addr < (sizeof(Registers) >> 1)) {
    ((int16*)(&registers))[addr] = value;
    return true;
  }
  return false;
}


void recvRegisters() {
  while (Serial.available())
    recvData();
}


void setup() {

  pinMode(BEEP_PIN, OUTPUT);
  pinMode(BATTERY_PIN, INPUT);

  pinMode(SENSOR_READ_A, INPUT);
  pinMode(SENSOR_READ_B, INPUT);
  pinMode(SENSOR_READ_C, INPUT);
  pinMode(SENSOR_SELECT_0, OUTPUT);
  pinMode(SENSOR_SELECT_1, OUTPUT);
  pinMode(SENSOR_SELECT_2, OUTPUT);

  pinMode(ENGINE_LEFT_POWER, OUTPUT);
  pinMode(ENGINE_RIGHT_POWER, OUTPUT);
  pinMode(ENGINE_LEFT_DIRECTION, OUTPUT);
  pinMode(ENGINE_RIGHT_DIRECTION, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(LEFT_VELOCITY), leftEngineInterrupt, CHANGE);
  attachInterrupt(digitalPinToInterrupt(RIGHT_VELOCITY), rightEngineInterrupt, CHANGE);

  Serial.begin(115200);
  Serial.flush();
}



void loop() {
  readHardware();

  setEnginesPower(registers.leftEngine, registers.rightEngine);

  delay(10);
  recvRegisters();
  sendRegisters();
}
