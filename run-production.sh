#!/bin/bash
echo "Starting Stock Market App in PRODUCTION mode..."
echo "Loading environment variables from .env.production"

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo "ERROR: .env.production file not found!"
    echo "Please create it from .env.example and add your API keys"
    exit 1
fi

# Load environment variables
set -a
source .env.production
set +a

# Run application
mvn spring-boot:run -Dspring-boot.run.profiles=production
