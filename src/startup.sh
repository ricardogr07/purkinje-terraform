#! /bin/bash

# Variables configurables
NOTEBOOK="ECG_BO_demo.ipynb"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).ipynb"
LOG_NAME="log_${OUT_NAME%.ipynb}.txt"

# 1. Instalar dependencias del sistema
apt-get update
apt-get install -y docker.io git libgl1 libxrender1 libxext6 libsm6 build-essential

# 2. Iniciar el servicio de Docker
systemctl start docker
usermod -aG docker $USER

# 3. Clonar el repositorio del proyecto
cd /root
git clone "$REPO_URL"
cd purkinje-learning

# 4. Construir imagen Docker con el Dockerfile del proyecto
docker build -t purkinje-opt .

# 5. Crear carpeta para guardar resultados fuera del contenedor
mkdir -p /root/output

# 6. Ejecutar el contenedor con:
#    - volumen de salida mapeado
#    - variable de entorno NOTEBOOK
#    - token.json montado para uso de la API de Gmail
docker run \
    -v /root/output:/outputs \
    -v /root/purkinje-learning/token.json:/app/token.json \
    -e NOTEBOOK="$NOTEBOOK" \
    purkinje-opt | tee /root/output/log.txt

# 7. Copiar cualquier archivo extra generado directamente en el repo (por ejemplo, imágenes, CSVs)
cp -r /root/purkinje-learning/output/* /root/output/ 2>/dev/null || true

# 8. Subir resultados a GCS si el notebook fue exitoso
if [ -f /root/output/output.ipynb ]; then
    echo "Notebook ejecutado exitosamente, subiendo resultados..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
else
    echo "ERROR: El archivo output.ipynb no se generó correctamente." >&2
    echo "Subiendo log de error..."
    gsutil cp /root/output/log.txt "$GCS_BUCKET/FAILED_$LOG_NAME"
    exit 1
fi

# 9. Ejecutar script de notificación por correo DENTRO del contenedor (requiere token.json y librerías)
docker run \
    -v /root/purkinje-learning/token.json:/app/token.json \
    purkinje-opt python3 /app/send_mail.py || echo "Error al enviar notificación"

# 10. Apagar la VM automáticamente
shutdown -h now
