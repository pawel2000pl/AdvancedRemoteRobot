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

#define SPEEDOMETER_INTERRUPS_PER_ROUND 64
#define WHEEL_LENGTH_CM 45

using int16 = signed short int;


template<typename T, typename U> constexpr int offsetOf(U T::*member)
{
    return (char*)&((T*)nullptr->*member) - (char*)nullptr;
}

struct Registers {

  int16 ping = 0x7FFF;

  int16 leftEngine = 0;
  int16 rightEngine = 0;

  int16 battery = 0; //mV
  int16 beep = 0;

  // cm/s
  int16 leftVelocity = 0;
  int16 rightVelocity = 0;

  int16 stopTimeout = 3000;
  int16 emergencyStop = 0;
  int16 sensorsStates[24] = {0};
  int16 sensorsEventStop[24] = {0}; // negative - stop when lower, positive - stop when higher, 0 - deactivated



};

const int WRITE_REGISTERS[] = {
  offsetOf(&Registers::ping),
  offsetOf(&Registers::leftEngine),
  offsetOf(&Registers::rightEngine),
  offsetOf(&Registers::beep),
  offsetOf(&Registers::sensorsEventStop),
  offsetOf(&Registers::sensorsEventStop)+2,
  offsetOf(&Registers::sensorsEventStop)+4,
  offsetOf(&Registers::sensorsEventStop)+8,
  offsetOf(&Registers::sensorsEventStop)+16,
  offsetOf(&Registers::sensorsEventStop)+24,
  offsetOf(&Registers::sensorsEventStop)+32,
  offsetOf(&Registers::sensorsEventStop)+36,
  offsetOf(&Registers::sensorsEventStop)+40,
  offsetOf(&Registers::sensorsEventStop)+44,
  offsetOf(&Registers::sensorsEventStop)+48,
  offsetOf(&Registers::sensorsEventStop)+52,
  offsetOf(&Registers::sensorsEventStop)+56,
  offsetOf(&Registers::sensorsEventStop)+60,
  offsetOf(&Registers::sensorsEventStop)+64,
  offsetOf(&Registers::sensorsEventStop)+68,
  offsetOf(&Registers::sensorsEventStop)+72,
  offsetOf(&Registers::sensorsEventStop)+76,
  offsetOf(&Registers::sensorsEventStop)+80,
  offsetOf(&Registers::sensorsEventStop)+84,
  offsetOf(&Registers::sensorsEventStop)+88,
  offsetOf(&Registers::sensorsEventStop)+92,
  -1
};

const int READ_REGISTERS[] = {
  offsetOf(&Registers::battery),
  offsetOf(&Registers::leftVelocity),
  offsetOf(&Registers::rightVelocity),
  offsetOf(&Registers::stopTimeout),
  offsetOf(&Registers::emergencyStop),
  offsetOf(&Registers::sensorsStates),
  offsetOf(&Registers::sensorsStates)+2,
  offsetOf(&Registers::sensorsStates)+4,
  offsetOf(&Registers::sensorsStates)+8,
  offsetOf(&Registers::sensorsStates)+16,
  offsetOf(&Registers::sensorsStates)+24,
  offsetOf(&Registers::sensorsStates)+32,
  offsetOf(&Registers::sensorsStates)+36,
  offsetOf(&Registers::sensorsStates)+40,
  offsetOf(&Registers::sensorsStates)+44,
  offsetOf(&Registers::sensorsStates)+48,
  offsetOf(&Registers::sensorsStates)+52,
  offsetOf(&Registers::sensorsStates)+56,
  offsetOf(&Registers::sensorsStates)+60,
  offsetOf(&Registers::sensorsStates)+64,
  offsetOf(&Registers::sensorsStates)+68,
  offsetOf(&Registers::sensorsStates)+72,
  offsetOf(&Registers::sensorsStates)+76,
  offsetOf(&Registers::sensorsStates)+80,
  offsetOf(&Registers::sensorsStates)+84,
  offsetOf(&Registers::sensorsStates)+88,
  offsetOf(&Registers::sensorsStates)+92,
  -1
};


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



void readHardware() {
    registers.battery = (unsigned long long)analogRead(BATTERY_PIN) * (5000 * 22) / ((47 + 22) * 1024);

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
  unsigned char buf[4] = {addr, absValue & 255, absValue >> 8, ((unsigned)(addr + 1) * (absValue + 1)) & 255};
  Serial.write(buf, 4);
}


void sendRegisters() {
  static Registers registersState;
  static int j = 0;
  int16 *registersPtr = (int16*)(&registers);
  int16 *registersStatePtr = (int16*)(&registersState);

  for ( int i = 0; READ_REGISTERS[i] >= 0; i++) {
    if (i == j || registersStatePtr[READ_REGISTERS[i]] != registersPtr[READ_REGISTERS[i]]) {
      sendData(READ_REGISTERS[i], registersPtr[READ_REGISTERS[i]]);
      registersStatePtr[READ_REGISTERS[i]] = registersPtr[READ_REGISTERS[i]];
    }
  }
  if (READ_REGISTERS[++j] < 0)
    j = 0;
}


bool recvData() {
  unsigned addr = Serial.read();
  int16 value = Serial.read();
  value += Serial.read() << 8;
  unsigned checksum = Serial.read();
  if (((addr + 1) * (abs((int)value) + 1)) & 255 == checksum && addr < sizeof(Registers)) {
    ((int16*)(&registers))[addr] = value;
    return true;
  }
  return false;
}


void recvRegisters() {
  bool error = false;
  while (Serial.available() >= 4)
    error = error || recvData();

  if (error && (Serial.available() & 3)) {
    delay(5);
    if (Serial.available() & 3) {
      while (Serial.available()) Serial.read();
    }
  }
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

  attachInterrupt(digitalPinToInterrupt(LEFT_VELOCITY), leftEngineInterrupt, CHANGE);
  attachInterrupt(digitalPinToInterrupt(RIGHT_VELOCITY), rightEngineInterrupt, CHANGE);

  Serial.begin(115200);
  Serial.flush();
}



void loop() {
  readHardware();

  delay(10);
  recvRegisters();
  sendRegisters();
}
