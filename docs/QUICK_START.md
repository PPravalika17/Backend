# Quick Start

## GitHub Secrets (Required)
1. Go to: Settings → Secrets → Actions
2. Add:
   - `STOCK_API_KEY`
   - `GEMINI_API_KEY`
   - `MYSQL_PASSWORD`

## Run Tests
```bash
mvn test
```

## Push to GitHub
```bash
git add .
git commit -m "Add CI/CD"
git push
```

## Test Summary
- **9 total tests** (3 per component)
- TradeServiceTest: 3 tests
- PortfolioServiceTest: 3 tests
- TradeControllerIntegrationTest: 3 tests
