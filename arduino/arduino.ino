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
#define SPEEDOMETER_INTERRUPS_PER_ROUND 32
#define WHEEL_LENGTH_MM 450
#define MAX_VELOCITY_DT (1000000llu * WHEEL_LENGTH_MM / (SPEEDOMETER_INTERRUPS_PER_ROUND * 25))
#define MIN_VELOCITY_DT (1000000llu * WHEEL_LENGTH_MM / (SPEEDOMETER_INTERRUPS_PER_ROUND * 1250))
#define MIN_VOLTAGE 10500
#define EMERGENCY_BACKWARD 200
#define MAX_ENGINE_CORRECTION 255

struct VelocityRecord {
  unsigned long long int lastTime = 0;
  unsigned long long int dt = 0;

  void update() {
    unsigned long long int t = micros();
    unsigned long long int ndt = t - lastTime;
    if (ndt < MIN_VELOCITY_DT) return;
    dt = ndt;
    lastTime = t;
  }
  
  void check() {
    if (micros() - lastTime > 5 * dt)
      dt = MAX_VELOCITY_DT;
  }

  int16 getVelocity() {
    return (dt >= MAX_VELOCITY_DT) ? 0 : constrain((1e6f * WHEEL_LENGTH_MM) / ((float)dt * SPEEDOMETER_INTERRUPS_PER_ROUND + 1), 0, 16384);
  }
};

VelocityRecord leftVelocity, rightVelocity;
unsigned long long int emergencyStopTime = 0;

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

  int leftPower = constrain(abs(left), 0, 255);
  int rightPower = constrain(abs(right), 0, 255);
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

    registers.leftVelocity = leftVelocity.getVelocity();
    registers.rightVelocity = rightVelocity.getVelocity();
    leftVelocity.check();
    rightVelocity.check();

    if (!registers.ping)
      return;

    // static unsigned int readLoop = 0;
    // unsigned int i = readLoop++ & 0b111;

    for (unsigned i=0;i<8;i++) {
      digitalWrite(SENSOR_SELECT_0, (i & 1) ? HIGH : LOW);
      digitalWrite(SENSOR_SELECT_1, (i & 2) ? HIGH : LOW);
      digitalWrite(SENSOR_SELECT_2, (i & 4) ? HIGH : LOW);
      delayMicroseconds(100);
      registers.sensorsStates[i] = analogRead(SENSOR_READ_A);
      registers.sensorsStates[i+8] = analogRead(SENSOR_READ_B);
      registers.sensorsStates[i+16] = analogRead(SENSOR_READ_C);
    }
    
    registers.emergencyStop = 0;
    for (int i=0;i<24;i++) {
      if (registers.sensorsEventStop[i] && (
        (registers.sensorsEventStop[i] < 0 && registers.sensorsStates[i] < -registers.sensorsEventStop[i]) ||
        (registers.sensorsEventStop[i] > 0 && registers.sensorsStates[i] > registers.sensorsEventStop[i])
      )) {
        if (!emergencyStopTime)
          emergencyStopTime = millis();
        registers.emergencyStop = 1;
        break;
      }
    }

    if (!registers.emergencyStop)
      emergencyStopTime = 0;
}


template<typename T> T sign(T value) {
  return value < 0 ? -1 : value > 0 ? 1 : 0;
}


template<typename T, typename S> T addSign(T value, S sgn) {
  return sgn < 0 ? -value : value;
}


float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


unsigned long long int engineControlTime = millis();
float engineCorrection = 0;

void writeHardware() {
  unsigned long long int ct = millis();
  float dt = 1e-3 * (float)(ct - engineControlTime);
  engineControlTime = ct;

  if (registers.autoEngines) {
    engineCorrection += 10*dt*((registers.leftVelocity*abs(registers.rightEngine) - registers.rightVelocity*abs(registers.leftEngine))/(1+abs(registers.leftVelocity)+abs(registers.rightVelocity)));
    engineCorrection = constrain(engineCorrection * pow(0.1, dt), -MAX_ENGINE_CORRECTION, +MAX_ENGINE_CORRECTION);
  } else engineCorrection = 0;

  int leftPower = registers.leftEngine ? constrain(abs(registers.leftEngine) - engineCorrection, 0, 255) : 0;
  int rightPower = registers.rightEngine ? constrain(abs(registers.rightEngine) + engineCorrection, 0, 255) : 0;

  int leftSignal = addSign(leftPower, sign(registers.leftEngine));
  int rightSignal = addSign(rightPower, sign(registers.rightEngine));
  
  if (registers.emergencyStop && ct - emergencyStopTime < registers.stopTimeout) {
    if (ct - emergencyStopTime < EMERGENCY_BACKWARD)
      setEnginesPower(-leftSignal, -rightSignal);
    else
      setEnginesPower(0, 0);
  } else
    setEnginesPower(leftSignal, rightSignal);

  digitalWrite(BEEP_PIN, (registers.beep || (registers.battery < MIN_VOLTAGE && ct & 0x100)) ? HIGH : LOW);
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

unsigned loopNo = 0;
unsigned long long int loopTime = millis();

void loop() {
  loopNo++;

  readHardware();
  writeHardware();
  pingChecker();

  do {
    recvRegisters();
  } while (millis() - loopTime < 5);
  loopTime = millis();

  if (registers.ping && (registers.query || (loopNo & 0xFF) == 0)) {
    registers.query = 0;
    sendRegisters();
  }
}
