#!/bin/bash
echo "Starting Stock Market App in TEST mode..."
echo "Using hardcoded API keys from application-test.properties"
mvn spring-boot:run -Dspring-boot.run.profiles=test
