#! /bin/bash

# Variables configurables
SCRIPT="ECG_BO_demo.py"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).log"
PY_ENV="/root/venv_purkinje"

# 1. Instalar dependencias del sistema
apt-get update
apt-get install -y python3 python3-pip git libgl1 libxrender1 libxext6 libsm6 build-essential

# 2. Crear entorno virtual
python3 -m venv "$PY_ENV"
source "$PY_ENV/bin/activate"

# 3. Clonar el repositorio
cd /root
git clone "$REPO_URL"
cd purkinje-learning

# 4. Instalar dependencias de Python
pip install --upgrade pip
pip install -r requirements.txt
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 5. Crear carpeta de salida
mkdir -p /root/output

# 6. Pasar token.json desde GCS a la VM
echo "Verificando si token.json existe en GCS..."
if gsutil ls "$GCS_BUCKET/token.json" > /dev/null 2>&1; then
    echo "token.json encontrado. Descargando..."
    gsutil cp "$GCS_BUCKET/token.json" /root/purkinje-learning/token.json
else
    echo "token.json no encontrado en GCS. Continuando sin él."
fi

# 7. Ejecutar el script directamente con logging
echo "Ejecutando script: $SCRIPT"
python "/root/purkinje-learning/$SCRIPT" &> "/root/output/$OUT_NAME"

# 8. Verificar y subir resultado a GCS
if grep -q "Elapsed time:" "/root/output/$OUT_NAME"; then
    echo "Script ejecutado exitosamente, subiendo resultados..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
    export EXECUTION_STATUS="SUCCESS"
else
    echo "ERROR: La ejecución del script falló." >&2
    echo "Subiendo log de error..."
    gsutil cp "/root/output/$OUT_NAME" "$GCS_BUCKET/FAILED_${OUT_NAME}"
    export EXECUTION_STATUS="FAILURE"
fi

# 9. Enviar notificación por correo
if [ -f /root/purkinje-learning/token.json ]; then
    echo "Enviando notificación por correo..."
    EXECUTION_STATUS="$EXECUTION_STATUS" python3 /root/purkinje-learning/send_mail.py || echo "Error al enviar correo"
else
    echo "No se encontró token.json, no se enviará correo"
fi

# 10. Apagar la VM automáticamente
shutdown -h now
