import os
import base64
from email.mime.text import MIMEText
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

# Load token
TOKEN_PATH = "/root/purkinje-learning/token.json"
creds = Credentials.from_authorized_user_file(TOKEN_PATH, scopes=["https://www.googleapis.com/auth/gmail.send"])

# Determine execution status
status = os.environ.get("EXECUTION_STATUS", "UNKNOWN")

if status == "SUCCESS":
    subject = "✅ Task completed: Purkinje notebook"
    body = "The notebook ECG_BO_demo.ipynb was successfully executed and is now available in GCS."
elif status == "FAILURE":
    subject = "❌ Execution error: Purkinje notebook"
    body = "The notebook ECG_BO_demo.ipynb failed to execute. Check the log in GCS."
else:
    subject = "⚠️ Unknown status: Purkinje notebook"
    body = "The execution status of the notebook could not be determined."

# Create Gmail service
service = build("gmail", "v1", credentials=creds)

# Construct and send message
message = MIMEText(body)
message["to"] = "rgr5882@gmail.com"
message["from"] = "rgr5882@gmail.com"
message["subject"] = subject

raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
send_message = {"raw": raw}
service.users().messages().send(userId="me", body=send_message).execute()
