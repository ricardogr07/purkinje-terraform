import os
import base64
from email.mime.text import MIMEText
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

# Cargar token
TOKEN_PATH = "/root/purkinje-learning/token.json"
creds = Credentials.from_authorized_user_file(TOKEN_PATH, scopes=["https://www.googleapis.com/auth/gmail.send"])

# Determinar estado
status = os.environ.get("EXECUTION_STATUS", "UNKNOWN")

if status == "SUCCESS":
    subject = "✅ Tarea finalizada: Purkinje notebook"
    body = "El notebook ECG_BO_demo.ipynb se ha ejecutado exitosamente y ya está disponible en GCS."
elif status == "FAILURE":
    subject = "❌ Error al ejecutar: Purkinje notebook"
    body = "El notebook ECG_BO_demo.ipynb no se ejecutó correctamente. Revisa el log en GCS."
else:
    subject = "⚠️ Estado desconocido: Purkinje notebook"
    body = "No se pudo determinar el estado de ejecución del notebook."

# Crear servicio Gmail
service = build("gmail", "v1", credentials=creds)

# Construir y enviar mensaje
message = MIMEText(body)
message["to"] = "rgr5882@gmail.com"
message["from"] = "rgr5882@gmail.com"
message["subject"] = subject

raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
send_message = {"raw": raw}
service.users().messages().send(userId="me", body=send_message).execute()
