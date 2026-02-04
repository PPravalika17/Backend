#!/bin/bash

##############################################################################
# Switch from H2 to MySQL Database - Simplified Version
# This script updates your Spring Boot configuration to use MySQL
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  Switch to MySQL Database"
echo "=========================================="
echo ""

# Check if we're in a Spring Boot project
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}[ERROR]${NC} pom.xml not found. Please run this script from your Spring Boot project root directory."
    exit 1
fi

# Get MySQL credentials
echo -e "${BLUE}[INPUT]${NC} Enter MySQL configuration:"
read -p "MySQL Host (default: localhost): " MYSQL_HOST
MYSQL_HOST=${MYSQL_HOST:-localhost}

read -p "MySQL Port (default: 3306): " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

read -p "MySQL Database Name (default: backend_db): " DB_NAME
DB_NAME=${DB_NAME:-backend_db}

read -p "MySQL Username (default: root): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-root}

read -sp "MySQL Password: " MYSQL_PASSWORD
echo ""
echo ""

# Warn about manual database creation
echo -e "${YELLOW}[NOTE]${NC} Please ensure the database '$DB_NAME' exists in MySQL."
echo -e "${YELLOW}[NOTE]${NC} If not, create it manually with:"
echo -e "   ${GREEN}CREATE DATABASE $DB_NAME;${NC}"
echo ""
read -p "Press ENTER to continue..."

# Backup application.properties
echo -e "${BLUE}[INFO]${NC} Backing up application.properties..."
if [ -f "src/main/resources/application.properties" ]; then
    cp src/main/resources/application.properties src/main/resources/application.properties.h2backup
    echo -e "${GREEN}[SUCCESS]${NC} Backup created: application.properties.h2backup"
else
    echo -e "${YELLOW}[WARNING]${NC} application.properties not found, will create new one"
fi

# Update pom.xml to include MySQL dependency
echo -e "${BLUE}[INFO]${NC} Checking pom.xml for MySQL dependency..."
if ! grep -q "mysql-connector-j" pom.xml; then
    echo -e "${YELLOW}[WARNING]${NC} MySQL dependency not found in pom.xml"
    echo -e "${BLUE}[INFO]${NC} Adding MySQL dependency..."
    
    # Create backup of pom.xml
    cp pom.xml pom.xml.bak
    
    # Add MySQL dependency before </dependencies>
    # For Windows/Git Bash compatibility, use a simpler approach
    awk '/<\/dependencies>/ {
        print "        <!-- MySQL Connector -->"
        print "        <dependency>"
        print "            <groupId>com.mysql</groupId>"
        print "            <artifactId>mysql-connector-j</artifactId>"
        print "            <scope>runtime</scope>"
        print "        </dependency>"
    }
    {print}' pom.xml > pom.xml.new && mv pom.xml.new pom.xml
    
    echo -e "${GREEN}[SUCCESS]${NC} MySQL dependency added!"
else
    echo -e "${GREEN}[SUCCESS]${NC} MySQL dependency already present"
fi

# Ensure resources directory exists
mkdir -p src/main/resources

# Update application.properties
echo -e "${BLUE}[INFO]${NC} Updating application.properties..."
cat > src/main/resources/application.properties << 'EOFMARKER'
# Server Configuration
server.port=8080

# MySQL Database Configuration
spring.datasource.url=jdbc:mysql://MYSQL_HOST_PLACEHOLDER:MYSQL_PORT_PLACEHOLDER/DB_NAME_PLACEHOLDER?useSSL=false&allowPublicKeyRetrieval=true
spring.datasource.username=MYSQL_USER_PLACEHOLDER
spring.datasource.password=MYSQL_PASSWORD_PLACEHOLDER
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA/Hibernate Configuration
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Logging
logging.level.org.springframework.web=INFO
logging.level.com.stockmarket=DEBUG

# Application Name
spring.application.name=stock-market-app

# Stock API Configuration
stock.api.url=https://stock.indianapi.in/trending
stock.api.key=sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v

# ========================================
# Note: H2 Console is now disabled
# To revert to H2, restore from: application.properties.h2backup
# ========================================
EOFMARKER

# Replace placeholders with actual values
sed -i "s|MYSQL_HOST_PLACEHOLDER|${MYSQL_HOST}|g" src/main/resources/application.properties
sed -i "s|MYSQL_PORT_PLACEHOLDER|${MYSQL_PORT}|g" src/main/resources/application.properties
sed -i "s|DB_NAME_PLACEHOLDER|${DB_NAME}|g" src/main/resources/application.properties
sed -i "s|MYSQL_USER_PLACEHOLDER|${MYSQL_USER}|g" src/main/resources/application.properties
sed -i "s|MYSQL_PASSWORD_PLACEHOLDER|${MYSQL_PASSWORD}|g" src/main/resources/application.properties

echo -e "${GREEN}[SUCCESS]${NC} Configuration updated!"

echo ""
echo -e "${BLUE}=========================================="
echo "  Summary"
echo "==========================================${NC}"
echo ""
echo "✅ MySQL dependency added to pom.xml"
echo "✅ application.properties updated"
echo "✅ Backup saved: application.properties.h2backup"
echo ""
echo "Database Configuration:"
echo "  Host: $MYSQL_HOST:$MYSQL_PORT"
echo "  Database: $DB_NAME"
echo "  Username: $MYSQL_USER"
echo ""
echo -e "${YELLOW}=========================================="
echo "  Next Steps"
echo "==========================================${NC}"
echo ""
echo "1. Make sure the database exists:"
echo -e "   ${GREEN}mysql -u $MYSQL_USER -p${NC}"
echo -e "   ${GREEN}CREATE DATABASE IF NOT EXISTS $DB_NAME;${NC}"
echo ""
echo "2. Rebuild the project:"
echo -e "   ${GREEN}mvn clean install${NC}"
echo ""
echo "3. Start the application:"
echo -e "   ${GREEN}mvn spring-boot:run${NC}"
echo ""
echo "4. Verify tables were created in MySQL:"
echo -e "   ${GREEN}mysql -u $MYSQL_USER -p -e 'USE $DB_NAME; SHOW TABLES;'${NC}"
echo ""
echo -e "${BLUE}ℹ️  To revert to H2:${NC}"
echo "   mv src/main/resources/application.properties.h2backup src/main/resources/application.properties"
echo ""
echo -e "${GREEN}🎉 Your app is now configured to use MySQL!${NC}"
echo ""