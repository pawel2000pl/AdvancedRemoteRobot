#include <Servo.h>
#include "registers.h"

#define BEEP_PIN 13
#define BATTERY_PIN 14
#define LEFT_VELOCITY 2
#define RIGHT_VELOCITY 3

#define LED_PIN 22

#define SENSOR_SELECT_0 15
#define SENSOR_SELECT_1 16
#define SENSOR_SELECT_2 17

#define SENSOR_READ_A 18
#define SENSOR_READ_B 19
#define SENSOR_READ_C 20

#define ENGINE_LEFT_POWER 5
#define ENGINE_RIGHT_POWER 6
#define ENGINE_LEFT_DIRECTION 8
#define ENGINE_RIGHT_DIRECTION 7

#define CAMERA_X 9
#define CAMERA_Y 10
#define CAMERA_Y_NEG 11

#define SENSOR_ENABLED 12

#define HELLO_VALUE 185
#define SPEEDOMETER_INTERRUPS_PER_ROUND 64
#define WHEEL_LENGTH_MM 450

struct VelocityRecord {
  unsigned long long int lastTime = 0;
  unsigned long long int dt = 0;

  void update() {
    unsigned long long int t = micros();
    dt = t - lastTime;
    lastTime = t;
  }
  
  void check(unsigned long long int t) {
    if (t - lastTime > 2 * dt)
      dt = 0xFFFFFFFF;
  }
};

VelocityRecord leftVelocity, rightVelocity;

Registers registers;
Servo cam_x_servo, cam_y_servo, cam_y_neg_servo;

void noPingAction() {
  registers.leftEngine = 0;
  registers.rightEngine = 0;
  registers.led = 0;
}


void pingChecker() {
  static unsigned long long int lastPingCheck = millis();
  unsigned long long int t = millis();
  unsigned long long int dt = t - lastPingCheck;
  lastPingCheck = t;
  if (registers.ping <= dt) registers.ping = 0;
  else registers.ping -= dt;
  if (!registers.ping)
    noPingAction();
}


void leftEngineInterrupt() {
  leftVelocity.update();
}

void rightEngineInterrupt() {
  rightVelocity.update();
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

    unsigned long long t = micros();
    registers.leftVelocity = constrain((1000000llu * WHEEL_LENGTH_MM) / (leftVelocity.dt * SPEEDOMETER_INTERRUPS_PER_ROUND + 1), -32767, 32767);
    registers.rightVelocity = constrain((1000000llu * WHEEL_LENGTH_MM) / (rightVelocity.dt * SPEEDOMETER_INTERRUPS_PER_ROUND + 1), -32767, 32767);
    leftVelocity.check(t);
    rightVelocity.check(t);

    if (!registers.ping)
      return;

    int sensor_pins[] = {SENSOR_SELECT_0, SENSOR_SELECT_1, SENSOR_SELECT_2};

    static unsigned int readLoop = 0;
    unsigned int i = readLoop++ & 0b111;

    registers.sensorsStates[i] = analogRead(SENSOR_READ_A);
    registers.sensorsStates[i+8] = analogRead(SENSOR_READ_B);
    registers.sensorsStates[i+16] = analogRead(SENSOR_READ_C);
    i++;
    digitalWrite(SENSOR_SELECT_0, (i & 1) ? HIGH : LOW);
    digitalWrite(SENSOR_SELECT_1, (i & 2) ? HIGH : LOW);
    digitalWrite(SENSOR_SELECT_2, (i & 4) ? HIGH : LOW);
    

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


void writeHardware() {
  setEnginesPower(registers.leftEngine, registers.rightEngine);
  digitalWrite(BEEP_PIN, registers.beep ? HIGH : LOW);
  digitalWrite(SENSOR_ENABLED, registers.ping ? HIGH : LOW);
  digitalWrite(LED_PIN, (!!registers.ping && !!registers.led) ? HIGH : LOW);

  if (registers.ping) {
    if (!cam_x_servo.attached()) cam_x_servo.attach(CAMERA_X); 
    if (!cam_y_servo.attached()) cam_y_servo.attach(CAMERA_Y);
    if (!cam_y_neg_servo.attached()) cam_y_neg_servo.attach(CAMERA_Y_NEG); 

    cam_x_servo.write(map(registers.cameraX, -255, 255, 0, 180));
    cam_y_servo.write(map(180-registers.cameraY, -255, 255, 30, 150));
    cam_y_neg_servo.write(map(registers.cameraY, -255, 255, 30, 150));
  } else {
    if (cam_x_servo.attached()) cam_x_servo.detach(); 
    if (cam_y_servo.attached()) cam_y_servo.detach();
    if (cam_y_neg_servo.attached()) cam_y_neg_servo.detach(); 
  }
}


unsigned char getChecksum(unsigned char addr, int16 value) {
  return (((unsigned long)addr + 1) * (((unsigned long)value & 0xFFFF) + 1)) & 255;
}


void sendData(unsigned char addr, int16 value) {
  unsigned char buf[5] = {HELLO_VALUE, addr, ((unsigned)value) & 255, ((unsigned)value) >> 8, getChecksum(addr, value)};
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
  while (Serial.read() != HELLO_VALUE)
    if (!Serial.available())
      return false;
  unsigned char buf[4] = {0};
  Serial.readBytes(buf, 4);
  unsigned char addr = buf[0];
  int16 value = (unsigned)buf[1] | ((unsigned)buf[2] << 8);
  if (getChecksum(addr, value) == buf[3] && addr < (sizeof(Registers) >> 1)) {
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

  pinMode(LEFT_VELOCITY, INPUT);
  pinMode(RIGHT_VELOCITY, INPUT);

  pinMode(BEEP_PIN, OUTPUT);
  pinMode(BATTERY_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);

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

  pinMode(SENSOR_ENABLED, OUTPUT);

  attachInterrupt(0, leftEngineInterrupt, RISING);
  attachInterrupt(1, rightEngineInterrupt, RISING);
  
  Serial.begin(115200);
  Serial.flush();
}


void loop() {
  readHardware();
  writeHardware();
  pingChecker();

  delay(10);
  recvRegisters();
  if (registers.ping)
    sendRegisters();
}
