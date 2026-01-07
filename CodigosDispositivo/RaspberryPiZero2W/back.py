import json
import pandas as pd
import joblib
import numpy as np
import time
import os
import sys
import pigpio
import requests
from tflite_runtime.interpreter import Interpreter
from sklearn.preprocessing import MinMaxScaler

# --- MÓDULOS PERSONALIZADOS ---
# Importación del controlador para el módulo GSM/GPRS SIM800L
import envio

# --- CONFIGURACIÓN DE RED Y REDUNDANCIA ---
# URL del servidor para envío vía Wi-Fi (canal de respaldo)
SERVER_URL_WIFI = "https://sep-expenses-lay-referred.trycloudflare.com/datos"

# --- CONFIGURACIÓN DE PERSISTENCIA ---
# Archivos locales para registro histórico y cola de reintentos (tolerancia a fallos)
CSV_FILE = "registros.csv"
PENDIENTES_FILE = "pendientes.json" 

# --- CONFIGURACIÓN DE HARDWARE (PIGPIO) ---
# Configuración del pin GPIO para lectura serial por software (Bit-Banging)
# Se utiliza el pin 24 para recibir datos (RX) del microcontrolador externo (Arduino)
RX_PIN = 24
BAUD = 115200

pi = pigpio.pi()
if not pi.connected:
    print("❌ Error: El demonio pigpiod no está activo. Ejecuta 'sudo pigpiod -s 10'.")
    sys.exit()

# Configuración del modo de lectura serial asíncrona
pi.set_mode(RX_PIN, pigpio.INPUT)
try:
    pi.bb_serial_read_open(RX_PIN, BAUD)
except:
    pass

# --- INICIALIZACIÓN DEL MÓDULO GPRS ---
# Se instancia y conecta el módem como canal principal de comunicación
modem = envio.Sim800L()
modem_listo = modem.conectar()

# --- CARGA DE MODELOS DE MACHINE LEARNING ---
# 1. Scaler: Para normalizar los datos de entrada igual que en el entrenamiento
scaler = joblib.load("scaler.pkl")

# 2. Intérprete TFLite: Motor de inferencia optimizado para dispositivos embebidos
interpreter = Interpreter(model_path="modelo_red.tflite")
interpreter.allocate_tensors()

# Obtención de punteros a los tensores de entrada y salida del modelo
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# --- INICIALIZACIÓN DE REGISTROS ---
# Creación del archivo CSV con cabeceras si no existe (Data Logging)
columnas = ['timestamp', 'no2', 'o3', 'temperatura', 'humedad', 'prediccion', 'latitud', 'longitud']
if not os.path.exists(CSV_FILE):
    pd.DataFrame(columns=columnas).to_csv(CSV_FILE, index=False)

# --- SISTEMA DE GESTIÓN DE COLAS (STORE & FORWARD) ---

def guardar_en_pendientes(payload):
    """
    Mecanismo de tolerancia a fallos:
    Si no hay conectividad, serializa y almacena el dato en un JSON local.
    """
    lista_pendientes = []

    # Lectura segura del archivo de pendientes existente
    if os.path.exists(PENDIENTES_FILE):
        try:
            with open(PENDIENTES_FILE, "r") as f:
                content = f.read().strip()
                if content:
                    lista_pendientes = json.loads(content)
        except Exception as e:
            print(f"⚠️ Error leyendo pendientes: {e}")
            lista_pendientes = []

    lista_pendientes.append(payload)

    # Escritura atómica de la nueva lista actualizada
    try:
        with open(PENDIENTES_FILE, "w") as f:
            json.dump(lista_pendientes, f)
        print(f"💾 Dato guardado en cola local (Timestamp: {payload['timestamp']})")
    except Exception as e:
        print(f"❌ Error guardando pendiente: {e}")

def intentar_reenvio_pendientes():
    """
    Sincronización diferida:
    Revisa la cola local y trata de vaciarla cuando se restablece la conexión.
    """
    if not os.path.exists(PENDIENTES_FILE):
        return

    try:
        with open(PENDIENTES_FILE, "r") as f:
            content = f.read().strip()
            if not content:
                return
            lista_pendientes = json.loads(content)
    except:
        return

    if not lista_pendientes:
        return

    print(f"🔄 Sincronizando {len(lista_pendientes)} registros pendientes...")

    pendientes_restantes = []

    for datos in lista_pendientes:
        # Reutilizamos la lógica de envío redundante (GPRS -> WiFi)
        enviado = gestionar_envio(datos, es_reenvio=True)

        if not enviado:
            pendientes_restantes.append(datos) # Persiste en cola si falla
        else:
            print(f"✅ Registro recuperado y sincronizado (TS: {datos['timestamp']})")
            time.sleep(1) # Control de flujo para evitar saturación

    # Actualización del archivo de pendientes con los remanentes
    if len(pendientes_restantes) < len(lista_pendientes):
        with open(PENDIENTES_FILE, "w") as f:
            json.dump(pendientes_restantes, f)
        if len(pendientes_restantes) == 0:
            print("🎉 Sincronización completa.")
            os.remove(PENDIENTES_FILE) 

# --- ESTRATEGIA DE COMUNICACIÓN REDUNDANTE ---

def enviar_por_wifi(payload):
    """
    Canal de respaldo: Envío HTTP a través de la interfaz de red de la RPi.
    """
    try:
        response = requests.post(SERVER_URL_WIFI, json=payload, timeout=5)
        if response.status_code == 200:
            return True
        else:
            print(f"⚠️ [WI-FI] Error Servidor: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        pass 
    except Exception as e:
        print(f"❌ [WI-FI] Error: {e}")
    return False

def gestionar_envio(datos, es_reenvio=False):
    """
    Orquestador de comunicación:
    Prioridad 1: Red celular (GPRS) mediante SIM800L.
    Prioridad 2: Red Wi-Fi local (Failover).
    """
    exito = False
    prefix = "[REENVÍO]" if es_reenvio else "[NUEVO]"

    # Intento Principal: GPRS
    if modem_listo:
        if not es_reenvio: print(f"📡 {prefix} Intentando vía GPRS...")
        exito = modem.enviar_datos(datos)

    # Intento Secundario: Wi-Fi (Failover)
    if not exito:
        if not es_reenvio: print(f"⚠️ {prefix} Fallo GPRS. Conmutando a Wi-Fi...")
        exito = enviar_por_wifi(datos)

    if exito and not es_reenvio:
        print(f"✅ {prefix} Transmisión exitosa.")

    return exito

print(f"✅ Sistema de Monitoreo Ambiental con IA e IoT iniciado.")

# --- BUCLE PRINCIPAL DE ADQUISICIÓN Y PROCESAMIENTO ---
data_buffer = ""

try:
    while True:
        # Lectura del buffer serial
        (count, data) = pi.bb_serial_read(RX_PIN)

        if count > 0:
            try:
                chunk = data.decode('utf-8', errors='ignore')
                data_buffer += chunk

                # Procesamiento por líneas completas (delimitadas por salto de línea)
                while "\n" in data_buffer:
                    line, data_buffer = data_buffer.split("\n", 1)
                    line = line.strip()

                    if not line or "{" not in line:
                        continue

                    try:
                        # Extracción y parsing del JSON recibido del sensor
                        json_str = line[line.find("{"):]
                        data_json = json.loads(json_str)

                        # Validación de integridad de datos
                        if all(k in data_json for k in ['NO2', 'O3', 'temp', 'hum']):

                            # --- ETAPA 1: PRE-PROCESAMIENTO E INFERENCIA (EDGE AI) ---
                            
                            # Creación del vector de características
                            df = pd.DataFrame([{
                                'no2': data_json['NO2'], 'ozone': data_json['O3'],
                                'temperature': data_json['temp'], 'humidity': data_json['hum']
                            }])
                            
                            # Normalización de datos usando el Scaler entrenado
                            scaled = scaler.transform(df)
                            input_data = np.array([list(dict(zip(df.columns, scaled[0])).values())], dtype=np.float32)
                            
                            # Ejecución de la inferencia en TFLite
                            interpreter.set_tensor(input_details[0]['index'], input_data)
                            interpreter.invoke()
                            
                            # Obtención de la clase predicha (Argmax)
                            predicted_class = int(np.argmax(interpreter.get_tensor(output_details[0]['index'])))

                            print(f"\n📊 Predicción Modelo IA: Clase {predicted_class}")

                            # --- ETAPA 2: ESTRUCTURACIÓN DE DATOS ---
                            timestamp_actual = int(time.time())
                            fila = {
                                'timestamp': timestamp_actual,
                                'no2': float(data_json['NO2']),
                                'o3': float(data_json['O3']),
                                'temperatura': float(data_json['temp']),
                                'humedad': float(data_json['hum']),
                                'prediccion': predicted_class, # Resultado de la IA
                                'latitud': float(data_json.get('lat', 0.0)),
                                'longitud': float(data_json.get('lon', 0.0))
                            }

                            # Guardado en histórico local (CSV)
                            pd.DataFrame([fila]).to_csv(CSV_FILE, mode='a', header=False, index=False)

                            # Preparación del payload para telemetría
                            datos_para_servidor = {
                                "humedad": fila['humedad'],
                                "no2": fila['no2'],
                                "o3": fila['o3'],
                                "prediccion": fila['prediccion'],
                                "temperatura": fila['temperatura'],
                                "timestamp": fila['timestamp'],
                                "latitud": fila['latitud'],
                                "longitud": fila['longitud']
                            }

                            # --- ETAPA 3: TELEMETRÍA ROBUSTA ---

                            # Intento de envío en tiempo real
                            enviado_actual = gestionar_envio(datos_para_servidor)

                            if enviado_actual:
                                # Si hay red, aprovechamos para vaciar la cola de pendientes
                                intentar_reenvio_pendientes()
                            else:
                                # Si falla, se activa el mecanismo de "Store & Forward"
                                print("⚠️ Fallo de conectividad. Activando almacenamiento local.")
                                guardar_en_pendientes(datos_para_servidor)

                        else:
                            print("⚠️ Trama de datos incompleta")

                    except json.JSONDecodeError:
                        pass
                    except Exception as e:
                        print(f"⚠️ Excepción en lógica principal: {e}")

            except Exception as e:
                print(f"Error Buffer: {e}")

        # Pequeña pausa para liberar CPU
        time.sleep(0.05)

except KeyboardInterrupt:
    print("\n⛔ Detención manual por usuario.")
finally:
    modem.cerrar()
    try:
        pi.bb_serial_read_close(RX_PIN)
    except:
        pass
    pi.stop()
