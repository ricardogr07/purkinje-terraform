RUN_TEST=$(curl -s -f "http://metadata.google.internal/computeMetadata/v1/instance/attributes/run_test" -H "Metadata-Flavor: Google" || echo "false")
USE_DOCKER=$(curl -s -f "http://metadata.google.internal/computeMetadata/v1/instance/attributes/use_docker" -H "Metadata-Flavor: Google" || echo "false")

if [ "$RUN_TEST" = "true" ]; then
  echo "Running GPU test script..."
  /root/purkinje-learning/startup/test.sh
else
  echo "RUN_TEST not enabled. Proceeding with normal startup..."
  if [ "$USE_DOCKER" = "true" ]; then
    /root/purkinje-learning/startup/startup.sh
  else
    /root/purkinje-learning/startup/startup_no_docker.sh
  fi
fi
