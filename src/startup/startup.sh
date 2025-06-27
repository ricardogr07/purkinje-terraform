#! /bin/bash

# Configurable variables
SCRIPT="ECG_BO_demo.py"
REPO_URL="https://github.com/ricardogr07/purkinje-learning.git"
GCS_BUCKET="gs://purkinje-results-bucket"
OUT_NAME="output_$(date +%Y%m%d_%H%M).log"
LOG_NAME="log_${OUT_NAME%.log}.txt"

# 1. Install system dependencies
apt-get update
apt-get install -y docker.io git libgl1 libxrender1 libxext6 libsm6 build-essential

# 2. Start Docker service
systemctl start docker
usermod -aG docker $USER

# 3. Clone the project repository
cd /root
git clone "$REPO_URL"
cd purkinje-learning

# 4. Copy token.json if it exists (from GitHub Actions cloned content)
if [ -f /root/purkinje-learning/src/token.json ]; then
    cp /root/purkinje-learning/src/token.json /root/purkinje-learning/token.json
fi

# 5. Build Docker image using the project's Dockerfile
docker build -t purkinje-opt .

# 6. Create folder to store results outside the container
mkdir -p /root/output

# 7. Run the container with:
#    - output volume mounted
#    - SCRIPT as environment variable
#    - token.json mounted for Gmail API use
docker run \
    -v /root/output:/outputs \
    -v /root/purkinje-learning/token.json:/app/token.json \
    -e SCRIPT="$SCRIPT" \
    purkinje-opt bash -c "python3 /app/\$SCRIPT" | tee /root/output/$OUT_NAME

# 8. Copy any extra files generated directly in the repo (e.g., images, CSVs)
cp -r /root/purkinje-learning/output/* /root/output/ 2>/dev/null || true

# 9. Upload results to GCS if execution was successful (check for key output)
if grep -q "Elapsed time:" "/root/output/$OUT_NAME"; then
    echo "Script executed successfully, uploading results..."
    gsutil cp /root/output/* "$GCS_BUCKET/"
else
    echo "ERROR: Script did not execute correctly or did not finish." >&2
    echo "Uploading error log..."
    gsutil cp "/root/output/$OUT_NAME" "$GCS_BUCKET/FAILED_$LOG_NAME"
    exit 1
fi

# 10. Run email notification script INSIDE the container (requires token.json and dependencies)
docker run \
    -v /root/purkinje-learning/token.json:/app/token.json \
    purkinje-opt python3 /app/send_mail.py || echo "Failed to send notification"

# 11. Automatically shut down the VM
shutdown -h now
