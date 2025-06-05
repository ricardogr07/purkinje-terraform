FROM python:3.10-slim

# 1. Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \\
    git build-essential libgl1 libxrender1 libxext6 libsm6 \\
    && rm -rf /var/lib/apt/lists/*

# 2. Crear carpeta de trabajo
WORKDIR /app
COPY . /app

# 3. Instalar paquetes de Python
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install jupyter nbconvert google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 4. Ejecutar notebook
CMD jupyter nbconvert \
    --to notebook \
    --execute /app/$NOTEBOOK \
    --output=/outputs/output.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --ExecutePreprocessor.kernel_name=python3