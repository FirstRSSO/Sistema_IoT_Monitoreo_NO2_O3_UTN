#include <SPI.h>
#include <Wire.h>
#include "DFRobot_OzoneSensor.h"
#include "DFRobot_MultiGasSensor.h"
#include "DFRobot_BME280.h"

#define COLLECT_NUMBER 20
#define Ozone_IICAddress OZONE_ADDRESS_3
#define NO2_I2C_ADDRESS 0x74
#define SEA_LEVEL_PRESSURE 1015.0f

#define SAMPLE_INTERVAL_MS 500    
#define REPORT_INTERVAL_MS 60000  
#define MAX_SAMPLES (REPORT_INTERVAL_MS / SAMPLE_INTERVAL_MS)

DFRobot_OzoneSensor Ozone;
DFRobot_GAS_I2C gas(&Wire, NO2_I2C_ADDRESS);
typedef DFRobot_BME280_IIC BME;
BME bme(&Wire, 0x77);

// --- Estructura GPS Corregida ---
// Aumentamos tamaño en 1 para el caracter nulo '\0'
struct
{
  char GPS_DATA[100]; // Aumentado un poco por seguridad
  bool GetData_Flag;   
  bool ParseData_Flag; 
  char UTCTime[12];    
  char latitude[12];   
  char N_S[3];         
  char longitude[13];  
  char E_W[3];         
  bool Usefull_Flag;   
} Save_Data;

const unsigned int gpsRxBufferLength = 600;
char gpsRxBuffer[gpsRxBufferLength];
unsigned int gpsRxLength = 0;

// Variables
unsigned long lastSample = 0;
unsigned long timer = 0;
volatile boolean heating = true;
// Coordenadas por defecto en caso de falla de GPS
float latitude = 0.35893;
float longitude = -78.11121;

int ozoneConcentration;
float no2Concentration;
float temperature, humidity, pressure, altitude;

float no2Buf[MAX_SAMPLES];
int o3Buf[MAX_SAMPLES];
float tempBuf[MAX_SAMPLES];
float humBuf[MAX_SAMPLES];
int sampleIdx = 0;

// Declaración de funciones para evitar errores de compilación
void collect_air_quality_data(int prob);
void send_mode_summary();
void Read_Gps();
void parse_GpsDATA();
void RST_GpsRxBuffer(void);
double nmeaLatToDecimal(String s, char ns);

void printLastOperateStatus(BME::eStatus_t eStatus) {
  switch (eStatus) {
    case BME::eStatusOK: Serial.println("BME280 OK"); break;
    case BME::eStatusErr: Serial.println("BME280 unknown error"); break;
    case BME::eStatusErrDeviceNotDetected: Serial.println("BME280 not detected"); break;
    case BME::eStatusErrParameter: Serial.println("BME280 parameter error"); break;
    default: Serial.println("BME280 unknown status"); break;
  }
}

void setup() {
  Serial.begin(115200);
  Serial1.begin(9600);

  // Inicializar sensores
  while (!Ozone.begin(Ozone_IICAddress)) {
    Serial.println("IIC Ozone Sensor is not found!");
    delay(1000);
  }
  Serial.println("Ozone OK");
  Ozone.setModes(MEASURE_MODE_PASSIVE);

  while (!gas.begin()) {
    Serial.println("IIC NO2 Sensor is not found!");
    delay(1000);
  }
  Serial.println("NO2 OK");
  gas.changeAcquireMode(gas.PASSIVITY);
  gas.setTempCompensation(gas.ON);

  bme.reset();
  while (bme.begin() != BME::eStatusOK) {
    Serial.println("BME280 fail");
    delay(2000);
  }
  Serial.println("BME280 OK");

  // Calentamiento
  timer = millis();
  Serial.print("Calentamiento: ");
  while (millis() - timer < 300000) {
    if ((millis() - timer) % 500 == 0) { // Feedback visual
      //Serial.print("*");
      //delay(10); // Pequeño delay para no saturar el puerto serie en este check
    }
  }
  Serial.println("\nInicio de muestreo...");
  heating = false;
  
  Save_Data.GetData_Flag = false;
  Save_Data.ParseData_Flag = false;
  Save_Data.Usefull_Flag = false;
}

void loop() {
  // GPS debe leerse constantemente
  Read_Gps(); 

  if (millis() - lastSample >= SAMPLE_INTERVAL_MS) {
    lastSample = millis();
    
    // 1. Recolectar datos
    collect_air_quality_data();
    
    // 2. Procesar GPS si hubo datos
    parse_GpsDATA(); 
    
    if (Save_Data.ParseData_Flag) {
      Save_Data.ParseData_Flag = false;
      if (Save_Data.Usefull_Flag) {
        Save_Data.Usefull_Flag = false;
        // Convertir char array a String para la función de conversión
        latitude = nmeaLatToDecimal(String(Save_Data.latitude), Save_Data.N_S[0]);
        longitude = nmeaLatToDecimal(String(Save_Data.longitude), Save_Data.E_W[0]);
      }
    }

    // 3. Guardar en Buffer
    if (sampleIdx < MAX_SAMPLES) {
      no2Buf[sampleIdx] = no2Concentration;
      o3Buf[sampleIdx] = ozoneConcentration;
      tempBuf[sampleIdx] = temperature;
      humBuf[sampleIdx] = humidity;
      sampleIdx++;
      // DEBUG: Imprimir un punto para saber que está vivo
      //Serial.print("."); 
    }

    // 4. Si el buffer está lleno (cada 60 seg), enviar reporte
    if (sampleIdx >= MAX_SAMPLES) {
      Serial.println(); // Salto de linea antes del JSON
      send_mode_summary();
      sampleIdx = 0;
    }
  }
}

void collect_air_quality_data() {
  no2Concentration = gas.readGasConcentrationPPM(); 
  ozoneConcentration = Ozone.readOzoneData(COLLECT_NUMBER);
  temperature = bme.getTemperature();
  pressure = bme.getPressure();
  altitude = bme.calAltitude(SEA_LEVEL_PRESSURE, pressure);
  humidity = bme.getHumidity();
}

float calcularModaFloat(float *arr, int n, float paso) {
  if (n == 0) return 0.0;
  float moda = arr[0];
  int maxCount = 0;

  for (int i = 0; i < n; i++) {
    float val = round(arr[i] / paso) * paso;
    int count = 0;
    for (int j = 0; j < n; j++) {
      float comp = round(arr[j] / paso) * paso;
      if (abs(comp - val) < 1e-3) count++;
    }
    if (count > maxCount) {
      maxCount = count;
      moda = val;
    }
  }
  return moda;
}

int calcularModaInt(int *arr, int n) {
  if (n == 0) return 0;
  int moda = arr[0];
  int maxCount = 0;
  for (int i = 0; i < n; i++) {
    int count = 0;
    for (int j = 0; j < n; j++) {
      if (arr[j] == arr[i]) count++;
    }
    if (count > maxCount) {
      maxCount = count;
      moda = arr[i];
    }
  }
  return moda;
}

void send_mode_summary() {
  float moda_no2 = calcularModaFloat(no2Buf, sampleIdx, 0.01);
  int moda_o3 = calcularModaInt(o3Buf, sampleIdx);
  float moda_temp = calcularModaFloat(tempBuf, sampleIdx, 0.1);
  float moda_hum = calcularModaFloat(humBuf, sampleIdx, 0.1);

  String json = "{";
  json += "\"NO2\":" + String(moda_no2, 2) + ",";
  json += "\"O3\":" + String(moda_o3) + ",";
  json += "\"temp\":" + String(moda_temp, 2) + ",";
  json += "\"hum\":" + String(moda_hum, 2) + ",";
  json += "\"lat\":" + String(latitude, 6) + ","; // GPS suele tener mas decimales
  json += "\"lon\":" + String(longitude, 6);
  json += "}";

  Serial.println(json);
}

void parse_GpsDATA() {
  char *subString;
  char *subStringNext;
  if (Save_Data.GetData_Flag) {
    Save_Data.GetData_Flag = false;

    // Buscar cabecera GPRMC o GNRMC manual si es necesario, 
    // pero aquí asumimos que GPS_DATA ya tiene la línea limpia desde Read_Gps.
    
    // Controlar que strstr no devuelva null antes de operar
    for (int i = 0; i <= 6; i++) {
      if (i == 0) {
        if ((subString = strstr(Save_Data.GPS_DATA, ",")) == NULL)
          return; // Error parsing
      } else {
        subString++;
        if ((subStringNext = strstr(subString, ",")) != NULL) {
          char usefullBuffer[2];
          int len = subStringNext - subString;
          
          switch (i) {
            case 1: 
                if(len < sizeof(Save_Data.UTCTime)) {
                    memcpy(Save_Data.UTCTime, subString, len); 
                    Save_Data.UTCTime[len] = '\0'; // IMPORTANTE: Null terminate
                }
                break;
            case 2: 
                memcpy(usefullBuffer, subString, len); 
                usefullBuffer[len] = '\0';
                break;
            case 3: 
                if(len < sizeof(Save_Data.latitude)) {
                    memcpy(Save_Data.latitude, subString, len); 
                    Save_Data.latitude[len] = '\0'; // IMPORTANTE
                }
                break;
            case 4: 
                if(len < sizeof(Save_Data.N_S)) {
                    memcpy(Save_Data.N_S, subString, len); 
                    Save_Data.N_S[len] = '\0'; // IMPORTANTE
                }
                break;
            case 5: 
                if(len < sizeof(Save_Data.longitude)) {
                    memcpy(Save_Data.longitude, subString, len); 
                    Save_Data.longitude[len] = '\0'; // IMPORTANTE
                }
                break;
            case 6: 
                if(len < sizeof(Save_Data.E_W)) {
                    memcpy(Save_Data.E_W, subString, len); 
                    Save_Data.E_W[len] = '\0'; // IMPORTANTE
                }
                break;
            default: break;
          }
          subString = subStringNext;
          Save_Data.ParseData_Flag = true;
          if (usefullBuffer[0] == 'A')
            Save_Data.Usefull_Flag = true;
          else if (usefullBuffer[0] == 'V')
            Save_Data.Usefull_Flag = false;
        }
      }
    }
  }
}

void Read_Gps() {
  while (Serial1.available()) {
    char c = Serial1.read();
    gpsRxBuffer[gpsRxLength++] = c;
    if (gpsRxLength >= gpsRxBufferLength) RST_GpsRxBuffer();
  }

  char *GPS_DATAHead;
  char *GPS_DATATail;
  if ((GPS_DATAHead = strstr(gpsRxBuffer, "$GPRMC,")) != NULL || (GPS_DATAHead = strstr(gpsRxBuffer, "$GNRMC,")) != NULL) {
    if (((GPS_DATATail = strstr(GPS_DATAHead, "\r\n")) != NULL) && (GPS_DATATail > GPS_DATAHead)) {
      int len = GPS_DATATail - GPS_DATAHead;
      if(len < sizeof(Save_Data.GPS_DATA)) { // Proteger desbordamiento
         memcpy(Save_Data.GPS_DATA, GPS_DATAHead, len);
         Save_Data.GPS_DATA[len] = '\0'; // Asegurar terminación
         Save_Data.GetData_Flag = true;
      }
      RST_GpsRxBuffer();
    }
  }
}

void RST_GpsRxBuffer(void) {
  // memset(gpsRxBuffer, 0, gpsRxBufferLength); 
  gpsRxLength = 0;
  gpsRxBuffer[0] = '\0';
}

double nmeaLatToDecimal(String s, char ns) {
  if (s.length() == 0) return 0.0;
  double val = s.toFloat();
  int deg = (int)(val / 100);
  double minutes = val - deg * 100;
  double dec = deg + minutes / 60.0;
  if (ns == 'S') dec = -dec;
  return dec;
}