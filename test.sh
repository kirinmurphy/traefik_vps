#!/bin/bash

set -e

# Install mkcert on the CI runner
echo "Installing mkcert..."
sudo apt-get update && sudo apt-get install -y mkcert
mkcert -install

# Create the certs directory and generate TLS certificates for localhost
mkdir -p certs
mkcert -cert-file ./certs/localhost.pem -key-file ./certs/localhost-key.pem localhost

# Start the Docker Compose stack in detached mode
echo "Starting Docker Compose stack..."
docker compose -f docker-compose.test.yml up -d

# Wait for the containers to be healthy and ready
echo "Waiting for Traefik to start..."
sleep 15

# Send an HTTPS request through Traefik to the Nginx service
echo "Testing Traefik HTTPS routing..."
# The -k flag is crucial here to ignore the self-signed certificate
RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost)

if [ "$RESPONSE" -eq 200 ]; then
  echo "✅ Success! Traefik is routing HTTPS traffic correctly."
else
  echo "❌ Error: Expected HTTP 200 but got $RESPONSE"
  exit 1
fi

# Clean upppppppperr!!!!!!
echo "Cleaning up..."
docker compose -f docker-compose.test.yml down