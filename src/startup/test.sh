#! /bin/bash

GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="test_output_$(date +%Y%m%d_%H%M).log"

# 1. Install system dependencies
apt-get update
apt-get install -y python3 python3-pip git libgl1 libxrender1 libxext6 libsm6 build-essential

# Enable swap
fallocate -l 32G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 2. Install NVIDIA GPU drivers and CUDA (if not already installed)
if [ ! -f /opt/google/cuda-installer/cuda_installer.pyz ]; then
  echo "Installing NVIDIA GPU drivers and CUDA..."
  mkdir -p /opt/google/cuda-installer
  cd /opt/google/cuda-installer || exit
  curl -fSsL -O https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz
  python3 cuda_installer.pyz install_cuda
else
  echo "CUDA installer already exists, skipping installation"
fi

# 3. Install Python dependencies
pip install --upgrade pip
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client torch

# Clone the test script from GCS bucket
gsutil cp "$GCS_BUCKET/test_gpu_pytorch.py" /root/test_gpu_pytorch.py

mkdir -p /root/output

# 5. Retrieve token.json from GCS to the VM
echo "Checking if token.json exists in GCS..."
if gsutil ls "$GCS_BUCKET/token.json" > /dev/null 2>&1; then
    echo "token.json found. Downloading..."
    gsutil cp "$GCS_BUCKET/token.json" /root/purkinje-learning/token.json
else
    echo "token.json not found in GCS. Continuing without it."
fi

# 6. Execute the script directly with logging
echo "=== Testing PyTorch GPU availability ==="
python3 /root/test_gpu_pytorch.py &> /root/output/$OUT_NAME

SCRIPT_EXIT_CODE=$?

# 7. Check exit code and upload result to GCS
if [ "$SCRIPT_EXIT_CODE" -eq 0 ]; then
    echo "Script executed successfully, uploading results..."
    gsutil cp /root/output/$OUT_NAME "$GCS_BUCKET/"
    export EXECUTION_STATUS="SUCCESS"
else
    echo "ERROR: Script execution failed with code $SCRIPT_EXIT_CODE." >&2
    echo "Uploading error log..."
    gsutil cp "/root/output/$OUT_NAME" "$GCS_BUCKET/FAILED_${OUT_NAME}"
    export EXECUTION_STATUS="FAILURE"
fi

# 8. Send email notification
if [ -f /root/purkinje-learning/token.json ]; then
    echo "Sending email notification..."
    EXECUTION_STATUS="$EXECUTION_STATUS" python3 /root/send_mail.py || echo "Failed to send email"
else
    echo "token.json not found, email will not be sent"
fi

# 9. Automatically shut down the VM
shutdown -h now
