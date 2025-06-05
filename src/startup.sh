#! /bin/bash

# Variables configurables
SCRIPT="ECG_BO_demo.py"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).log"
LOG_NAME="log_${OUT_NAME%.log}.txt"

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

# 4. Copiar token.json si existe desde el archivo clonado por GitHub Actions
if [ -f /root/purkinje-learning/src/token.json ]; then
    cp /root/purkinje-learning/src/token.json /root/purkinje-learning/token.json
fi

# 5. Construir imagen Docker con el Dockerfile del proyecto
docker build -t purkinje-opt .

# 6. Crear carpeta para guardar resultados fuera del contenedor
mkdir -p /root/output

# 7. Ejecutar el contenedor con:
#    - volumen de salida mapeado
#    - variable de entorno SCRIPT
#    - token.json montado para uso de la API de Gmail
docker run \
    -v /root/output:/outputs \
    -v /root/purkinje-learning/token.json:/app/token.json \
    -e SCRIPT="$SCRIPT" \
    purkinje-opt bash -c "python3 /app/\$SCRIPT" | tee /root/output/$OUT_NAME

# 8. Copiar cualquier archivo extra generado directamente en el repo (por ejemplo, imágenes, CSVs)
cp -r /root/purkinje-learning/output/* /root/output/ 2>/dev/null || true

# 9. Subir resultados a GCS si la ejecución fue exitosa (verifica que haya archivos clave)
if grep -q "Elapsed time:" "/root/output/$OUT_NAME"; then
    echo "Script ejecutado exitosamente, subiendo resultados..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
else
    echo "ERROR: El script no se ejecutó correctamente o no terminó." >&2
    echo "Subiendo log de error..."
    gsutil cp "/root/output/$OUT_NAME" "$GCS_BUCKET/FAILED_$LOG_NAME"
    exit 1
fi

# 10. Ejecutar script de notificación por correo DENTRO del contenedor (requiere token.json y librerías)
docker run \
    -v /root/purkinje-learning/token.json:/app/token.json \
    purkinje-opt python3 /app/send_mail.py || echo "Error al enviar notificación"

# 11. Apagar la VM automáticamente
shutdown -h now
