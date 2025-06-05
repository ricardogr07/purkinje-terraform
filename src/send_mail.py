import os
import base64
from email.mime.text import MIMEText
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

# Cargar token
TOKEN_PATH = "/root/purkinje-learning/token.json"
creds = Credentials.from_authorized_user_file(TOKEN_PATH, scopes=["https://www.googleapis.com/auth/gmail.send"])

# Crear servicio
service = build("gmail", "v1", credentials=creds)

# Construir mensaje
message = MIMEText("El notebook ECG_BO_demo.ipynb se ha ejecutado exitosamente y ya está disponible en GCS")
message["to"] = "rgr5882@gmail.com"
message["from"] = "rgr5882@gmail.com"
message["subject"] = "✅ Tarea finalizada: Purkinje notebook"

# Convertir y enviar
raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
send_message = {"raw": raw}
service.users().messages().send(userId="me", body=send_message).execute()
