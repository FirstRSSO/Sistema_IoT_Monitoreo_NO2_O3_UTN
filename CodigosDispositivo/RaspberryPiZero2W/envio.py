import serial
import time
import json
import sys

class Sim800L:
    def __init__(self, port="/dev/serial0", baud=9600):
        self.port = port
        self.baud = baud
        self.ser = None
        self.apn = "internet.cnt.net.ec"
        self.server = "miappsim9001.loca.lt" # ¡OJO: Verifica que este link siga activo!
        self.resource = "/datos"

    def conectar(self):
        """Abre la conexión serial e inicializa el GPRS"""
        try:
            print("📡 Inicializando SIM800L...")
            self.ser = serial.Serial(self.port, self.baud, timeout=1)
            time.sleep(2)
            
            # Configuración base
            if not self._send_at("AT"): return False
            self._send_at("AT+CFUN=1")
            self._send_at('AT+SAPBR=3,1,"CONTYPE","GPRS"')
            self._send_at(f'AT+SAPBR=3,1,"APN","{self.apn}"')
            
            # Intentar activar GPRS (Si ya está activo, dará error, pero lo ignoramos)
            self._send_at("AT+SAPBR=1,1", wait=3)
            self._send_at("AT+SAPBR=2,1")
            
            # Configuración HTTP inicial
            self._send_at("AT+HTTPINIT")
            self._send_at('AT+HTTPPARA="CID",1')
            self._send_at(f'AT+HTTPPARA="URL","http://{self.server}{self.resource}"')
            self._send_at('AT+HTTPPARA="CONTENT","application/json"')
            
            print("✅ SIM800L Listo para enviar.")
            return True
        except Exception as e:
            print(f"❌ Error conectando SIM800L: {e}")
            return False

    def enviar_datos(self, data_dict):
        """Recibe un diccionario, lo convierte a JSON y lo envía"""
        if not self.ser or not self.ser.is_open:
            print("⚠️ Puerto serial cerrado, intentando reconectar...")
            self.conectar()

        try:
            # Convertir diccionario a JSON string
            json_payload = json.dumps(data_dict)
            json_length = len(json_payload)
            
            print(f"📤 Enviando: {json_payload}")

            # Comandos de envío
            self._send_at(f"AT+HTTPDATA={json_length},10000")
            time.sleep(0.5)
            self.ser.write(json_payload.encode())
            time.sleep(2) # Tiempo para que el modem procese los datos
            
            # Ejecutar POST
            reply = self._send_at("AT+HTTPACTION=1", wait=8) # Espera más larga para la respuesta de red

            if "+HTTPACTION: 1,200" in reply:
                print("✅ Enviado con éxito (200 OK)")
                # Opcional: Leer respuesta del servidor
                # print(self._send_at("AT+HTTPREAD", wait=3))
                return True
            else:
                print(f"⚠️ Error en envío HTTP. Respuesta: {reply}")
                return False

        except Exception as e:
            print(f"❌ Error crítico enviando: {e}")
            return False

    def cerrar(self):
        """Cierra la conexión HTTP y el puerto"""
        if self.ser and self.ser.is_open:
            self._send_at("AT+HTTPTERM")
            self.ser.close()
            print("🔒 Conexión SIM800L cerrada.")

    def _send_at(self, cmd, wait=1):
        """Función interna para enviar comandos raw"""
        if not self.ser: return ""
        try:
            self.ser.write((cmd + "\r\n").encode())
            time.sleep(wait)
            reply = self.ser.read_all().decode(errors="ignore").strip()
            # print(f"DEBUG: {cmd} -> {reply}") # Descomenta para ver todo el tráfico AT
            return reply
        except Exception as e:
            print(f"Error Serial: {e}")
            return ""
