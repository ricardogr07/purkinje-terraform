#! /bin/bash

# Variables configurables
NOTEBOOK="ECG_BO_demo.ipynb"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).ipynb"
LOG_NAME="log_${OUT_NAME%.ipynb}.txt"
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
pip install jupyter nbconvert google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 5. Crear carpeta de salida
mkdir -p /root/output

# 6. Pasar token.json desde GCS a la VM
echo "Verificando si token.json existe en GCS..."
if gsutil ls gs://purkinje-results-bucket/token.json > /dev/null 2>&1; then
    echo "token.json encontrado. Descargando..."
    gsutil cp gs://purkinje-results-bucket/token.json /root/purkinje-learning/token.json
else
    echo "token.json no encontrado en GCS. Continuando sin él."
fi

# 7. Ejecutar el notebook directamente con logging
echo "Ejecutando notebook: $NOTEBOOK"
jupyter nbconvert \
    --to notebook \
    --execute "/root/purkinje-learning/$NOTEBOOK" \
    --output="/root/output/$OUT_NAME" \
    --ExecutePreprocessor.timeout=-1 \
    --ExecutePreprocessor.kernel_name=python3 \
    &> /root/output/log.txt

# 8. Verificar y subir resultado a GCS
if [ -f "/root/output/$OUT_NAME" ]; then
    echo "Notebook ejecutado exitosamente, subiendo resultados..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
    export EXECUTION_STATUS="SUCCESS"
else
    echo "ERROR: El archivo $OUT_NAME no se generó correctamente." >&2
    echo "Subiendo log de error..."
    gsutil cp /root/output/log.txt "$GCS_BUCKET/FAILED_$LOG_NAME"
    export EXECUTION_STATUS="FAILURE"
fi

# 9. Enviar notificación por correo si existe token.json
if [ -f /root/purkinje-learning/token.json ]; then
    echo "Enviando notificación por correo..."
    EXECUTION_STATUS="$EXECUTION_STATUS" python3 /root/purkinje-learning/send_mail.py || echo "Error al enviar correo"
else
    echo "No se encontró token.json, no se enviará correo"
fi

# 10. Apagar la VM automáticamente
shutdown -h now
