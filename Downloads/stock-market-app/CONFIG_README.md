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
