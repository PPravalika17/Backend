#!/bin/bash

###############################################################################
# Stock Market App - API Key Refactoring Automation Script
# This script automates the process of refactoring API keys from source code
# to configuration files with separate test and production profiles.
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Stock Market App - API Key Refactoring Script           ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

###############################################################################
# Function: Print status message
###############################################################################
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

###############################################################################
# Function: Backup original files
###############################################################################
backup_files() {
    print_info "Creating backups of original files..."
    
    BACKUP_DIR="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup GeminiService.java
    if [ -f "${PROJECT_ROOT}/src/main/java/com/stockmarket/service/GeminiService.java" ]; then
        cp "${PROJECT_ROOT}/src/main/java/com/stockmarket/service/GeminiService.java" \
           "${BACKUP_DIR}/GeminiService.java.bak"
        print_status "Backed up GeminiService.java"
    fi
    
    # Backup application.properties
    if [ -f "${PROJECT_ROOT}/src/main/resources/application.properties" ]; then
        cp "${PROJECT_ROOT}/src/main/resources/application.properties" \
           "${BACKUP_DIR}/application.properties.bak"
        print_status "Backed up application.properties"
    fi
    
    print_status "Backup created at: ${BACKUP_DIR}"
}

###############################################################################
# Function: Create directory structure
###############################################################################
create_directories() {
    print_info "Creating required directories..."
    
    mkdir -p "${PROJECT_ROOT}/src/main/resources"
    mkdir -p "${PROJECT_ROOT}/src/main/java/com/stockmarket/service"
    
    print_status "Directory structure verified"
}

###############################################################################
# Function: Copy configuration files
###############################################################################
copy_config_files() {
    print_info "Setting up configuration files..."
    
    # Copy test profile properties
    cat > "${PROJECT_ROOT}/src/main/resources/application-test.properties" << 'EOF'
# Server Configuration
server.port=8080

# MySQL Database Configuration
spring.datasource.url=jdbc:mysql://localhost:3306/stockmarketdb?useSSL=false&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=n3u3da!
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

# Stock API Configuration (Test - Hardcoded)
stock.api.url=https://stock.indianapi.in/trending
stock.api.nse.url=https://stock.indianapi.in/NSE_most_active
stock.api.bse.url=https://stock.indianapi.in/BSE_most_active
stock.api.key=sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v

# Gemini API Configuration (Test - Hardcoded)
gemini.api.key=AIzaSyBtODJB9iZ_dvx4sp7xhkhjyCEDLXwDTUg
gemini.api.url=https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent
EOF
    print_status "Created application-test.properties"
    
    # Copy production profile properties
    cat > "${PROJECT_ROOT}/src/main/resources/application-production.properties" << 'EOF'
# Server Configuration
server.port=${SERVER_PORT:8080}

# MySQL Database Configuration
spring.datasource.url=${DATABASE_URL:jdbc:mysql://localhost:3306/stockmarketdb?useSSL=false&allowPublicKeyRetrieval=true}
spring.datasource.username=${DATABASE_USERNAME:root}
spring.datasource.password=${DATABASE_PASSWORD}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA/Hibernate Configuration
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.jpa.hibernate.ddl-auto=${JPA_DDL_AUTO:update}
spring.jpa.show-sql=${JPA_SHOW_SQL:false}
spring.jpa.properties.hibernate.format_sql=${JPA_FORMAT_SQL:false}

# Logging
logging.level.org.springframework.web=${LOG_LEVEL_WEB:INFO}
logging.level.com.stockmarket=${LOG_LEVEL_APP:INFO}

# Application Name
spring.application.name=stock-market-app

# Stock API Configuration (Production - Environment Variables)
stock.api.url=${STOCK_API_URL:https://stock.indianapi.in/trending}
stock.api.nse.url=${STOCK_API_NSE_URL:https://stock.indianapi.in/NSE_most_active}
stock.api.bse.url=${STOCK_API_BSE_URL:https://stock.indianapi.in/BSE_most_active}
stock.api.key=${STOCK_API_KEY}

# Gemini API Configuration (Production - Environment Variables)
gemini.api.key=${GEMINI_API_KEY}
gemini.api.url=${GEMINI_API_URL:https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent}
EOF
    print_status "Created application-production.properties"
    
    # Update main application.properties to use test profile by default
    cat > "${PROJECT_ROOT}/src/main/resources/application.properties" << 'EOF'
# Active Profile (Change to 'production' for production environment)
spring.profiles.active=test

# ========================================
# Profile-specific configurations are loaded from:
# - application-test.properties (for test profile)
# - application-production.properties (for production profile)
# ========================================
EOF
    print_status "Updated application.properties with profile selection"
}

###############################################################################
# Function: Update GeminiService.java
###############################################################################
update_gemini_service() {
    print_info "Updating GeminiService.java to use configuration properties..."
    
    cat > "${PROJECT_ROOT}/src/main/java/com/stockmarket/service/GeminiService.java" << 'EOF'
package com.stockmarket.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@Service
public class GeminiService {
    
    @Value("${gemini.api.key}")
    private String API_KEY;
    
    @Value("${gemini.api.url}")
    private String GEMINI_URL;

    public String getAIResponse(String prompt) {
        RestTemplate restTemplate = new RestTemplate();
        
        // Build the full URL with API key
        String url = GEMINI_URL + "?key=" + API_KEY;

        // The structure MUST be contents -> parts -> text
        Map<String, Object> textPart = Map.of("text", prompt);
        Map<String, Object> contentsPart = Map.of("parts", List.of(textPart));
        Map<String, Object> requestBody = Map.of("contents", List.of(contentsPart));

        try {
            // Sending the request to Google
            Map<String, Object> response = restTemplate.postForObject(url, requestBody, Map.class);

            // Digging through the JSON response to find the text
            List candidates = (List) response.get("candidates");
            Map firstCandidate = (Map) candidates.get(0);
            Map content = (Map) firstCandidate.get("content");
            List parts = (List) content.get("parts");
            Map firstPart = (Map) parts.get(0);

            return (String) firstPart.get("text");
        } catch (Exception e) {
            e.printStackTrace(); // This will print the full technical error in your IntelliJ console
            return "AI Error: " + e.getMessage();
        }
    }
}
EOF
    print_status "Updated GeminiService.java with @Value annotations"
}

###############################################################################
# Function: Create environment files
###############################################################################
create_env_files() {
    print_info "Creating environment configuration files..."
    
    # Create .env.example
    cat > "${PROJECT_ROOT}/.env.example" << 'EOF'
# Server Configuration
SERVER_PORT=8080

# Database Configuration
DATABASE_URL=jdbc:mysql://localhost:3306/stockmarketdb?useSSL=false&allowPublicKeyRetrieval=true
DATABASE_USERNAME=root
DATABASE_PASSWORD=your_database_password_here

# JPA Configuration
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
JPA_FORMAT_SQL=false

# Logging
LOG_LEVEL_WEB=INFO
LOG_LEVEL_APP=INFO

# Stock API Configuration
STOCK_API_URL=https://stock.indianapi.in/trending
STOCK_API_NSE_URL=https://stock.indianapi.in/NSE_most_active
STOCK_API_BSE_URL=https://stock.indianapi.in/BSE_most_active
STOCK_API_KEY=your_stock_api_key_here

# Gemini API Configuration
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_API_URL=https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent
EOF
    print_status "Created .env.example"
    
    # Create actual .env.production (should not be committed to git)
    cat > "${PROJECT_ROOT}/.env.production" << 'EOF'
# Server Configuration
SERVER_PORT=8080

# Database Configuration
DATABASE_URL=jdbc:mysql://localhost:3306/stockmarketdb?useSSL=false&allowPublicKeyRetrieval=true
DATABASE_USERNAME=root
DATABASE_PASSWORD=n3u3da!

# JPA Configuration
JPA_DDL_AUTO=update
JPA_SHOW_SQL=false
JPA_FORMAT_SQL=false

# Logging
LOG_LEVEL_WEB=INFO
LOG_LEVEL_APP=INFO

# Stock API Configuration
STOCK_API_URL=https://stock.indianapi.in/trending
STOCK_API_NSE_URL=https://stock.indianapi.in/NSE_most_active
STOCK_API_BSE_URL=https://stock.indianapi.in/BSE_most_active
STOCK_API_KEY=sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v

# Gemini API Configuration
GEMINI_API_KEY=AIzaSyBtODJB9iZ_dvx4sp7xhkhjyCEDLXwDTUg
GEMINI_API_URL=https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent
EOF
    print_status "Created .env.production"
}

###############################################################################
# Function: Update .gitignore
###############################################################################
update_gitignore() {
    print_info "Updating .gitignore to protect sensitive files..."
    
    cat > "${PROJECT_ROOT}/.gitignore" << 'EOF'
# Compiled class files
*.class
target/

# Log files
*.log

# Environment files (IMPORTANT - Never commit these!)
.env
.env.production
.env.local
*.env

# Application properties with secrets
application-production.properties

# IDE files
.idea/
*.iml
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties

# Spring Boot
spring-boot-starter-parent/

# Backups
backups/
EOF
    print_status "Updated .gitignore"
}

###############################################################################
# Function: Create helper scripts
###############################################################################
create_helper_scripts() {
    print_info "Creating helper scripts..."
    
    # Script to run in test mode
    cat > "${PROJECT_ROOT}/run-test.sh" << 'EOF'
#!/bin/bash
echo "Starting Stock Market App in TEST mode..."
echo "Using hardcoded API keys from application-test.properties"
mvn spring-boot:run -Dspring-boot.run.profiles=test
EOF
    chmod +x "${PROJECT_ROOT}/run-test.sh"
    print_status "Created run-test.sh"
    
    # Script to run in production mode
    cat > "${PROJECT_ROOT}/run-production.sh" << 'EOF'
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
EOF
    chmod +x "${PROJECT_ROOT}/run-production.sh"
    print_status "Created run-production.sh"
    
    # Script to package for production
    cat > "${PROJECT_ROOT}/package-production.sh" << 'EOF'
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
EOF
    chmod +x "${PROJECT_ROOT}/package-production.sh"
    print_status "Created package-production.sh"
}

###############################################################################
# Function: Create README documentation
###############################################################################
create_readme() {
    print_info "Creating configuration documentation..."
    
    cat > "${PROJECT_ROOT}/CONFIG_README.md" << 'EOF'
# API Key Configuration Guide

## Overview
This application uses Spring Boot profiles to manage different configurations for test and production environments.

## Profiles

### Test Profile (Default)
- **Profile Name**: `test`
- **Configuration File**: `src/main/resources/application-test.properties`
- **API Keys**: Hardcoded in the properties file
- **Use Case**: Local development and testing

### Production Profile
- **Profile Name**: `production`
- **Configuration File**: `src/main/resources/application-production.properties`
- **API Keys**: Loaded from environment variables
- **Use Case**: Production deployment

## Environment Variables (Production)

Create a `.env.production` file or set these environment variables:

```bash
# Stock API
STOCK_API_KEY=your_stock_api_key_here

# Gemini AI API
GEMINI_API_KEY=your_gemini_api_key_here

# Database
DATABASE_PASSWORD=your_database_password_here
```

## Running the Application

### Test Mode (Development)
```bash
# Option 1: Using helper script
./run-test.sh

# Option 2: Using Maven
mvn spring-boot:run -Dspring-boot.run.profiles=test

# Option 3: Using application.properties default
mvn spring-boot:run
```

### Production Mode
```bash
# Option 1: Using helper script (loads .env.production)
./run-production.sh

# Option 2: Set environment variables manually
export STOCK_API_KEY=your_key
export GEMINI_API_KEY=your_key
export DATABASE_PASSWORD=your_password
mvn spring-boot:run -Dspring-boot.run.profiles=production

# Option 3: Run packaged JAR
java -jar target/stock-market-app-1.0.0.jar --spring.profiles.active=production
```

## Security Best Practices

1. **Never commit sensitive files**:
   - `.env.production`
   - `application-production.properties` (if it contains secrets)

2. **Use .gitignore**: 
   - Already configured to exclude sensitive files

3. **Environment Variables**:
   - Use system environment variables in production
   - Use secret management services (AWS Secrets Manager, Azure Key Vault, etc.)

4. **API Key Rotation**:
   - Regularly rotate your API keys
   - Update environment variables accordingly

## File Structure

```
stock-market-app/
├── src/main/resources/
│   ├── application.properties              # Profile selector
│   ├── application-test.properties         # Test config (with hardcoded keys)
│   └── application-production.properties   # Production config (uses env vars)
├── .env.example                            # Template for environment variables
├── .env.production                         # Actual production env vars (not in git)
├── .gitignore                              # Protects sensitive files
├── run-test.sh                             # Helper script for test mode
├── run-production.sh                       # Helper script for production mode
└── package-production.sh                   # Build script for deployment
```

## Troubleshooting

### API Keys Not Working
1. Check if correct profile is active
2. Verify environment variables are set
3. Restart application after changing config

### Profile Not Loading
1. Check `spring.profiles.active` in application.properties
2. Verify profile-specific file exists
3. Check logs for profile activation message

## Additional Configuration

To add new API keys or configuration:

1. Add to `application-test.properties` with hardcoded value
2. Add to `application-production.properties` with `${ENV_VAR_NAME}`
3. Add to `.env.example` as documentation
4. Add to `.env.production` with actual value
5. Use `@Value("${property.name}")` in Java code
EOF
    print_status "Created CONFIG_README.md"
}

###############################################################################
# Function: Verify configuration
###############################################################################
verify_configuration() {
    print_info "Verifying configuration..."
    
    local errors=0
    
    # Check if required files exist
    if [ ! -f "${PROJECT_ROOT}/src/main/resources/application-test.properties" ]; then
        print_error "application-test.properties not found"
        ((errors++))
    fi
    
    if [ ! -f "${PROJECT_ROOT}/src/main/resources/application-production.properties" ]; then
        print_error "application-production.properties not found"
        ((errors++))
    fi
    
    if [ ! -f "${PROJECT_ROOT}/src/main/java/com/stockmarket/service/GeminiService.java" ]; then
        print_error "GeminiService.java not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "All required files are in place"
        return 0
    else
        print_error "Configuration verification failed with $errors error(s)"
        return 1
    fi
}

###############################################################################
# Main execution
###############################################################################
main() {
    echo ""
    print_info "Starting refactoring process..."
    echo ""
    
    # Step 1: Backup
    backup_files
    echo ""
    
    # Step 2: Create directories
    create_directories
    echo ""
    
    # Step 3: Copy configuration files
    copy_config_files
    echo ""
    
    # Step 4: Update Java files
    update_gemini_service
    echo ""
    
    # Step 5: Create environment files
    create_env_files
    echo ""
    
    # Step 6: Update .gitignore
    update_gitignore
    echo ""
    
    # Step 7: Create helper scripts
    create_helper_scripts
    echo ""
    
    # Step 8: Create documentation
    create_readme
    echo ""
    
    # Step 9: Verify
    if verify_configuration; then
        echo ""
        print_status "✓ Refactoring completed successfully!"
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  Next Steps:                                              ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  1. Review CONFIG_README.md for detailed instructions     ║${NC}"
        echo -e "${GREEN}║  2. Test with: ./run-test.sh                              ║${NC}"
        echo -e "${GREEN}║  3. For production: Update .env.production with real keys ║${NC}"
        echo -e "${GREEN}║  4. Deploy with: ./run-production.sh                      ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        print_error "Refactoring completed with errors. Please review the output."
        exit 1
    fi
}

# Run main function
main