#!/bin/bash
echo "Packaging Stock Market App for PRODUCTION deployment..."

# Clean and package
mvn clean package -DskipTests

echo ""
echo "✓ Application packaged successfully!"
echo ""
echo "To run in production:"
echo "1. Set environment variables on your server"
echo "2. Run: java -jar target/stock-market-app-1.0.0.jar --spring.profiles.active=production"
echo ""
echo "Or use Docker with environment variables from .env.production"
