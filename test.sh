#!/bin/bash

set -e

echo "Installing mkcert..."
sudo apt-get update && sudo apt-get install -y mkcert
mkcert -install

mkdir -p certs
mkcert -cert-file ./certs/localhost.pem -key-file ./certs/localhost-key.pem localhost

echo "Starting Docker Compose stack..."
docker compose -f docker-compose.test.yml up -d

echo "Waiting for Traefik to start..."
sleep 15

echo "Testing Traefik HTTPS routing..."
RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost)

if [ "$RESPONSE" -eq 200 ]; then
  echo "✅ Success! Traefik is routing HTTPS traffic correctly."
else
  echo "❌ Error: Expected HTTP 200 but got $RESPONSE"
  exit 1
fi

echo "Cleaning up..."
docker compose -f docker-compose.test.yml down
