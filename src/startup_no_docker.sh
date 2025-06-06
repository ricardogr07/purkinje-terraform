#! /bin/bash

# Configurable variables
SCRIPT="ECG_BO_demo.py"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).log"

# 1. Install system dependencies
apt-get update
apt-get install -y python3 python3-pip git libgl1 libxrender1 libxext6 libsm6 build-essential

# Enable swap
fallocate -l 32G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 2. Clone the repository
cd /root
git clone "$REPO_URL"
cd purkinje-learning

# 3. Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client

# 4. Create output folder
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
echo "Running script: $SCRIPT"
python3 "/root/purkinje-learning/$SCRIPT" &> "/root/output/$OUT_NAME"
SCRIPT_EXIT_CODE=$?

# 7. Check exit code and upload result to GCS
if [ "$SCRIPT_EXIT_CODE" -eq 0 ]; then
    echo "Script executed successfully, uploading results..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
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
    EXECUTION_STATUS="$EXECUTION_STATUS" python3 /root/purkinje-learning/send_mail.py || echo "Failed to send email"
else
    echo "token.json not found, email will not be sent"
fi

# 9. Automatically shut down the VM
shutdown -h now
