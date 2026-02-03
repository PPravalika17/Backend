#!/bin/bash

echo "=========================================="
echo "  Starting Stock Market Trading Platform"
echo "=========================================="
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "ERROR: Maven is not installed. Please install Maven first."
    exit 1
fi

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "ERROR: Java is not installed. Please install Java 17 or higher."
    exit 1
fi

echo "Building application..."
mvn clean install -DskipTests

if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful! Starting application..."
    echo ""
    echo "Access the application at:"
    echo "  - Frontend: http://localhost:8080/index.html"
    echo "  - H2 Console: http://localhost:8080/h2-console"
    echo "  - API: http://localhost:8080/api"
    echo ""
    mvn spring-boot:run
else
    echo ""
    echo "Build failed. Please check the errors above."
    exit 1
fi
