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

# --- IMPORTAR EL MÓDULO SIM800L ---
import envio

# --- CONFIGURACIÓN DE RED (RESPALDO WI-FI) ---
SERVER_URL_WIFI = "http://driving-game-selecting-vatican.trycloudflare.com/datos"

# --- CONFIGURACIÓN DE ARCHIVOS ---
CSV_FILE = "registros.csv"
PENDIENTES_FILE = "pendientes.json" # Archivo para cola de reintentos

# --- CONFIGURACIÓN PIGPIO (Arduino RX) ---
RX_PIN = 24
BAUD = 115200

pi = pigpio.pi()
if not pi.connected:
    print("❌ Error: Ejecuta 'sudo pigpiod -s 10' primero.")
    sys.exit()

pi.set_mode(RX_PIN, pigpio.INPUT)
try:
    pi.bb_serial_read_open(RX_PIN, BAUD)
except:
    pass

# --- INICIALIZAR MODULO SIM800L ---
modem = envio.Sim800L()
modem_listo = modem.conectar()

# --- CARGA DE MODELOS ML ---
scaler = joblib.load("scaler.pkl")
interpreter = Interpreter(model_path="modelo_red.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# --- CONFIGURACIÓN CSV ---
columnas = ['timestamp', 'no2', 'o3', 'temperatura', 'humedad', 'prediccion', 'latitud', 'longitud']
if not os.path.exists(CSV_FILE):
    pd.DataFrame(columns=columnas).to_csv(CSV_FILE, index=False)

# --- FUNCIONES DE GESTIÓN DE PENDIENTES ---

def guardar_en_pendientes(payload):
    """Guarda el dato no enviado en un archivo JSON local"""
    lista_pendientes = []

    # Cargar existentes si el archivo ya existe
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

    # Guardar lista actualizada
    try:
        with open(PENDIENTES_FILE, "w") as f:
            json.dump(lista_pendientes, f)
        print(f"💾 Dato guardado en cola local (Timestamp: {payload['timestamp']})")
    except Exception as e:
        print(f"❌ Error guardando pendiente: {e}")

def intentar_reenvio_pendientes():
    """Revisa si hay datos pendientes y trata de enviarlos"""
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

    print(f"🔄 Intentando reenvío de {len(lista_pendientes)} datos pendientes...")

    pendientes_restantes = []

    for datos in lista_pendientes:
        # Intentamos enviar usando la función unificada (primero GPRS, luego WiFi)
        enviado = gestionar_envio(datos, es_reenvio=True)

        if not enviado:
            pendientes_restantes.append(datos) # Si falla de nuevo, se mantiene en cola
        else:
            print(f"✅ Pendiente recuperado y enviado (TS: {datos['timestamp']})")
            time.sleep(1) # Pequeña pausa para no saturar

    # Actualizar el archivo JSON con los que aún no se pudieron enviar
    if len(pendientes_restantes) < len(lista_pendientes):
        with open(PENDIENTES_FILE, "w") as f:
            json.dump(pendientes_restantes, f)
        if len(pendientes_restantes) == 0:
            print("🎉 Todos los pendientes han sido sincronizados.")
            os.remove(PENDIENTES_FILE) # Limpiar archivo si está vacío

# --- FUNCIÓN DE RESPALDO WI-FI ---
def enviar_por_wifi(payload):
    """Intenta enviar los datos usando la conexión de internet de la RPi"""
    try:
        # print(f"🌐 Intentando envío por Wi-Fi a {SERVER_URL_WIFI}...")
        # Comentado para no saturar log en reenvíos masivos
        response = requests.post(SERVER_URL_WIFI, json=payload, timeout=5)

        if response.status_code == 200:
            return True
        else:
            print(f"⚠️ [WI-FI] Error Servidor: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        pass # Silencioso para no ensuciar log
    except Exception as e:
        print(f"❌ [WI-FI] Error: {e}")
    return False

def gestionar_envio(datos, es_reenvio=False):
    """Maneja la lógica de intentos GPRS -> WiFi"""
    exito = False
    prefix = "[REENVÍO]" if es_reenvio else "[NUEVO]"

    # INTENTO 1: SIM800L
    if modem_listo:
        if not es_reenvio: print(f"📡 {prefix} Intentando GPRS...")
        exito = modem.enviar_datos(datos)

    # INTENTO 2: WI-FI (Si GPRS falló)
    if not exito:
        if not es_reenvio: print(f"⚠️ {prefix} Fallo GPRS. Probando Wi-Fi...")
        exito = enviar_por_wifi(datos)

    if exito and not es_reenvio:
        print(f"✅ {prefix} Enviado correctamente.")

    return exito

print(f"✅ Sistema con Redundancia y Cola de Reintentos Listo.")

data_buffer = ""

try:
    while True:
        (count, data) = pi.bb_serial_read(RX_PIN)

        if count > 0:
            try:
                chunk = data.decode('utf-8', errors='ignore')
                data_buffer += chunk

                while "\n" in data_buffer:
                    line, data_buffer = data_buffer.split("\n", 1)
                    line = line.strip()

                    if not line or "{" not in line:
                        continue

                    try:
                        json_str = line[line.find("{"):]
                        data_json = json.loads(json_str)

                        if all(k in data_json for k in ['NO2', 'O3', 'temp', 'hum']):

                            # --- 1. PROCESAMIENTO ML ---
                            df = pd.DataFrame([{
                                'no2': data_json['NO2'], 'ozone': data_json['O3'],
                                'temperature': data_json['temp'], 'humidity': data_json['hum']
                            }])
                            scaled = scaler.transform(df)
                            input_data = np.array([list(dict(zip(df.columns, scaled[0])).values())], dtype=np.float32)
                            interpreter.set_tensor(input_details[0]['index'], input_data)
                            interpreter.invoke()
                            predicted_class = int(np.argmax(interpreter.get_tensor(output_details[0]['index'])))

                            print(f"\n📊 Predicción: Clase {predicted_class}")

                            # --- 2. PREPARAR DATOS ---
                            timestamp_actual = int(time.time())
                            fila = {
                                'timestamp': timestamp_actual,
                                'no2': float(data_json['NO2']),
                                'o3': float(data_json['O3']),
                                'temperatura': float(data_json['temp']),
                                'humedad': float(data_json['hum']),
                                'prediccion': predicted_class,
                                'latitud': float(data_json.get('lat', 0.0)),
                                'longitud': float(data_json.get('lon', 0.0))
                            }

                            # Guardar en CSV Histórico (siempre se guarda)
                            pd.DataFrame([fila]).to_csv(CSV_FILE, mode='a', header=False, index=False)

                            # Payload para servidor
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

                            # --- 3. LÓGICA DE ENVÍO CON RECUPERACIÓN ---

                            # Primero intentamos enviar el dato actual
                            enviado_actual = gestionar_envio(datos_para_servidor)

                            if enviado_actual:
                                # Si hay conexión (el actual se envió), revisamos si hay cola pendiente
                                intentar_reenvio_pendientes()
                            else:
                                # Si falló todo, guardamos en la cola para después
                                print("⚠️ No hubo conexión. Guardando en pendientes...")
                                guardar_en_pendientes(datos_para_servidor)

                        else:
                            print("⚠️ JSON incompleto")

                    except json.JSONDecodeError:
                        pass
                    except Exception as e:
                        print(f"⚠️ Error Lógica: {e}")

            except Exception as e:
                print(f"Error Buffer: {e}")

        time.sleep(0.05)

except KeyboardInterrupt:
    print("\n⛔ Salida de usuario.")
finally:
    modem.cerrar()
    try:
        pi.bb_serial_read_close(RX_PIN)
    except:
        pass
    pi.stop()
