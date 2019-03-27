#include <Arduino.h>

#include <DHT12.h>
const uint8_t DHT_SDA=0, DHT_SCL=2;
DHT12 dht;

#include <PMserial.h>
SerialPM pms(PMS3003, Serial);

#include <Homie.h>
const uint16_t SEND_INTERVAL = 300;
HomieNode tempNode("temperature", "temperature");
HomieNode rhumNode("humidity", "humidity");
HomieNode pm01Node("pm01", "PM1");
HomieNode pm25Node("pm25", "PM2.5");
HomieNode pm10Node("pm10", "PM10");
void dhtSetup();
void pmsSetup();
void setupHandler() {
  dhtSetup();
  pmsSetup();
}
void dhtLoop();
void pmsLoop();
void loopHandler() {
  static uint32_t lastSent = 0;
  if (millis() - lastSent >= SEND_INTERVAL * 1000UL || lastSent == 0) {
    dhtLoop();
    pmsLoop();
    lastSent = millis();
  }
}

void setup() {
  Serial.begin(9600);
  Serial << endl << endl;
  Homie_setBrand("AQmon");
  Homie_setFirmware("AQmon", GIT_TAG);
  Homie.setSetupFunction(setupHandler).setLoopFunction(loopHandler);

  Wire.begin(DHT_SDA, DHT_SCL);
  // DHT12: temperature
  tempNode.advertise("sensor");
  tempNode.advertise("unit");
  tempNode.advertise("degrees");
  // DHT12: (relative) humidity
  rhumNode.advertise("sensor");
  rhumNode.advertise("unit");
  rhumNode.advertise("percentage");
  
  pms.init();
  // PMS3003: PM1 concentration
  pm01Node.advertise("sensor");
  pm01Node.advertise("unit");
  pm01Node.advertise("concentration");
  // PMS3003: PM2.5 concentration
  pm25Node.advertise("sensor");
  pm25Node.advertise("unit");
  pm25Node.advertise("concentration");
  // PMS3003: PM10 concentration
  pm10Node.advertise("sensor");
  pm10Node.advertise("unit");
  pm10Node.advertise("concentration");

  Homie.disableLedFeedback();
#ifndef DEBUG
  Homie.disableLogging();
#endif
  Homie.setup();
}

void loop() {
  Homie.loop();
}

void dhtSetup() {
  // DHT12: temperature
  tempNode.setProperty("sensor").send("DHT12");
  tempNode.setProperty("unit").send("c");
  // DHT12: (relative) humidity
  rhumNode.setProperty("sensor").send("DHT12");
  rhumNode.setProperty("unit").send("percentage");
}

void dhtLoop(){
#ifdef DEBUG
  switch (dht.read()){
  case DHT12_OK:
    Homie.getLogger().printf("DHT12: %5.1f °C, %5.1f %%\n", dht.temperature, dht.humidity);
    break;
  case DHT12_ERROR_CHECKSUM:
    Homie.getLogger().printf("DTH12: checksum error\n");
    return;
  case DHT12_ERROR_CONNECT:
    Homie.getLogger().printf("DTH12: connect error\n");
    return;
  case DHT12_MISSING_BYTES:
    Homie.getLogger().printf("DTH12: missing bytes\n");
    return;
  default:
    Homie.getLogger().printf("DTH12: unknown bytes\n");
    return;
  }
#else
  if (dht.read() != DHT12_OK)
    return;
#endif
  // DHT12: temperature (1 decimal place)
  tempNode.setProperty("degrees").send(String(dht.temperature, 1));
  // DHT12: (relative) humidity (1 decimal place)
  tempNode.setProperty("percentage").send(String(dht.humidity, 1));
}

void pmsSetup() {
  // PMS3003: PM1 concentration
  pm01Node.setProperty("sensor").send("PMS3003");
  pm01Node.setProperty("unit").send("ug/m3");
  // PMS3003: PM2.5 concentration
  pm25Node.setProperty("sensor").send("PMS3003");
  pm25Node.setProperty("unit").send("ug/m3");
  // PMS3003: PM10 concentration
  pm10Node.setProperty("sensor").send("PMS3003");
  pm10Node.setProperty("unit").send("ug/m3");
}

void pmsLoop(){
#ifdef DEBUG
  switch (pms.read()) {
  case pms.OK:
    Homie.getLogger().printf("PMS3003: %2d, %2d, %2d [ug/m3]\n",
      pms.pm01,pms.pm25,pms.pm10);
    break;
  case pms.ERROR_TIMEOUT:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_TIMEOUT);
    return;
  case pms.ERROR_MSG_HEADER:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_MSG_HEADER);
    return;
  case pms.ERROR_MSG_BODY:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_MSG_BODY);
    return;
  case pms.ERROR_MSG_START:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_MSG_START);
    return;
  case pms.ERROR_MSG_LENGHT:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_MSG_LENGHT);
    return;
  case pms.ERROR_MSG_CKSUM:
    Homie.getLogger().printf("PMS3003: %s\n", PMS_ERROR_MSG_CKSUM);
    return;
  default:
    Homie.getLogger().printf("PMS3003: unknown error\n");
    return;
  }
#else
  if (pms.read() != pms.OK)
    return;
#endif
  // PMS3003: PM1 concentration
  pm01Node.setProperty("concentration").send(String(pms.pm01));
  // PMS3003: PM2.5 concentration
  pm25Node.setProperty("concentration").send(String(pms.pm25));
  // PMS3003: PM10 concentration
  pm10Node.setProperty("concentration").send(String(pms.pm10));
}
