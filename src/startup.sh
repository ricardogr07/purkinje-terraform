#! /bin/bash

# Variables configurables
NOTEBOOK="ECG_BO_demo.ipynb"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).ipynb"
LOG_NAME="log_${OUT_NAME%.ipynb}.txt"

# 1. Instalar dependencias
apt-get update
apt-get install -y docker.io git libgl1 libxrender1 libxext6 libsm6 build-essential

# 2. Iniciar Docker
systemctl start docker
usermod -aG docker $USER

# 3. Clonar el repositorio
cd /root
git clone "$REPO_URL"
cd purkinje-learning

# 4. Crear Dockerfile dinámicamente
cat <<EOF > Dockerfile
FROM python:3.10-slim

RUN apt-get update && apt-get install -y \\
    git build-essential libgl1 libxrender1 libxext6 libsm6 \\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN pip install --upgrade pip && pip install -r requirements.txt && pip install jupyter nbconvert

CMD jupyter nbconvert \
    --to notebook \
    --execute /app/$NOTEBOOK \
    --output=/outputs/output.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --ExecutePreprocessor.kernel_name=python3

EOF

# 5. Construir la imagen
docker build -t purkinje-opt .

# 6. Crear carpeta de salida
mkdir -p /root/output

# 7. Ejecutar el contenedor y guardar log
docker run -v /root/output:/outputs purkinje-opt > /root/output/log.txt 2>&1

# 8. Copiar resultados adicionales del repo original (si existen)
cp -r /root/purkinje-learning/output/* /root/output/ 2>/dev/null || true

# 9. Verificar y subir todo a GCS
if [ -f /root/output/output.ipynb ]; then
    echo "Notebook ejecutado exitosamente, subiendo resultados..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
else
    echo "ERROR: El archivo output.ipynb no se generó correctamente." >&2
    echo "Subiendo log de error..."
    gsutil cp /root/output/log.txt "$GCS_BUCKET/FAILED_$LOG_NAME"
    exit 1
fi

# 10. Apagar la VM
shutdown -h now
