FROM python:3.10-slim

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    git build-essential libgl1 libxrender1 libxext6 libsm6 \
    && rm -rf /var/lib/apt/lists/*

# 2. Create working directory
WORKDIR /app
COPY . /app

# 3. Install Python packages
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install jupyter nbconvert google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 4. Run notebook
CMD jupyter nbconvert \
    --to notebook \
    --execute /app/$NOTEBOOK \
    --output=/outputs/output.ipynb \
    --ExecutePreprocessor.timeout=-1 \
    --ExecutePreprocessor.kernel_name=python3
