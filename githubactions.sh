#!/bin/bash

################################################################################
# GitHub Actions CI/CD Setup Automation Script
# Stock Market Trading Platform - Production Ready Setup
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

################################################################################
# Main Functions
################################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local errors=0
    
    # Check if running in project root
    if [ ! -f "pom.xml" ]; then
        print_error "pom.xml not found. Please run this script from your project root directory."
        errors=$((errors + 1))
    else
        print_success "Found pom.xml"
    fi
    
    # Check for Maven
    if command -v mvn &> /dev/null; then
        print_success "Maven is installed"
    else
        print_error "Maven is not installed. Please install Maven first."
        errors=$((errors + 1))
    fi
    
    # Check for Git
    if command -v git &> /dev/null; then
        print_success "Git is installed"
    else
        print_error "Git is not installed. Please install Git first."
        errors=$((errors + 1))
    fi
    
    # Check Java version
    if command -v java &> /dev/null; then
        print_success "Java is installed"
    else
        print_error "Java is not installed. Please install Java 17."
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "Prerequisites check failed. Please fix the errors above."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

create_directory_structure() {
    print_header "Creating Directory Structure"
    
    mkdir -p .github/workflows
    mkdir -p src/test/java/com/stockmarket/service
    mkdir -p src/test/java/com/stockmarket/controller
    mkdir -p docs
    
    print_success "Directory structure created"
}

create_test_files() {
    print_header "Creating Test Files (9 tests total)"
    
    # TradeServiceTest (3 tests)
    cat > src/test/java/com/stockmarket/service/TradeServiceTest.java << 'TESTEOF'
package com.stockmarket.service;

import com.stockmarket.dto.TradeRequest;
import com.stockmarket.dto.TradeResponse;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.repository.TradeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TradeServiceTest {
    @Mock private TradeRepository tradeRepository;
    @Mock private PortfolioRepository portfolioRepository;
    @InjectMocks private TradeService tradeService;
    private TradeRequest buyRequest;
    private Portfolio portfolio;
    private Trade trade;

    @BeforeEach
    void setUp() {
        buyRequest = new TradeRequest();
        buyRequest.setTickerId("RELIANCE.NS");
        buyRequest.setCompanyName("Reliance Industries");
        buyRequest.setTradeType("BUY");
        buyRequest.setQuantity(10);
        buyRequest.setPrice(2850.50);
        buyRequest.setTotalAmount(28505.00);
        portfolio = new Portfolio();
        portfolio.setId(1L);
        portfolio.setTickerId("RELIANCE.NS");
        portfolio.setTotalQuantity(10);
        portfolio.setAveragePrice(2850.50);
        trade = new Trade();
        trade.setId(1L);
        trade.setTickerId("RELIANCE.NS");
        trade.setTradeType("BUY");
        trade.setQuantity(10);
        trade.setPrice(2850.50);
    }

    @Test
    void testExecuteTrade_BuyNewStock_Success() {
        when(portfolioRepository.findByTickerId(buyRequest.getTickerId())).thenReturn(Optional.empty());
        when(tradeRepository.save(any(Trade.class))).thenReturn(trade);
        when(portfolioRepository.save(any(Portfolio.class))).thenReturn(portfolio);
        TradeResponse response = tradeService.executeTrade(buyRequest);
        assertNotNull(response);
        assertEquals("SUCCESS", response.getStatus());
        verify(tradeRepository, times(1)).save(any(Trade.class));
    }

    @Test
    void testExecuteTrade_InvalidTickerId() {
        buyRequest.setTickerId(null);
        TradeResponse response = tradeService.executeTrade(buyRequest);
        assertEquals("ERROR", response.getStatus());
        assertEquals("Ticker ID is required", response.getMessage());
    }

    @Test
    void testSellFromPortfolio_Success() {
        when(portfolioRepository.findByTickerId("RELIANCE.NS")).thenReturn(Optional.of(portfolio));
        when(tradeRepository.save(any(Trade.class))).thenReturn(trade);
        TradeResponse response = tradeService.sellFromPortfolio("RELIANCE.NS", 5, 2900.00);
        assertEquals("SUCCESS", response.getStatus());
    }
}
TESTEOF
    print_success "Created TradeServiceTest.java (3 tests)"
    
    # PortfolioServiceTest (3 tests)
    cat > src/test/java/com/stockmarket/service/PortfolioServiceTest.java << 'TESTEOF'
package com.stockmarket.service;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.PortfolioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PortfolioServiceTest {
    @Mock private PortfolioRepository portfolioRepository;
    @InjectMocks private PortfolioService portfolioService;
    private Portfolio portfolio;

    @BeforeEach
    void setUp() {
        portfolio = new Portfolio();
        portfolio.setTickerId("RELIANCE.NS");
        portfolio.setTotalQuantity(10);
        portfolio.setAveragePrice(2850.50);
        portfolio.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void testGetAllPortfolio() {
        List<Portfolio> portfolios = new ArrayList<>();
        portfolios.add(portfolio);
        when(portfolioRepository.findAll()).thenReturn(portfolios);
        List<Portfolio> result = portfolioService.getAllPortfolio();
        assertEquals(1, result.size());
        assertEquals("RELIANCE.NS", result.get(0).getTickerId());
    }

    @Test
    void testImportFromCSV_ValidFile() {
        String csv = "EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP\n" +
                    "NSE,RELIANCE.NS,\"Reliance\",10,2850.50,2026-02-04T10:30:00\n";
        MockMultipartFile file = new MockMultipartFile("file", "test.csv", "text/csv", csv.getBytes());
        when(portfolioRepository.findByTickerId(anyString())).thenReturn(Optional.empty());
        when(portfolioRepository.save(any(Portfolio.class))).thenReturn(portfolio);
        Map<String, Object> result = portfolioService.importFromCSV(file);
        assertTrue((Boolean) result.get("success"));
    }

    @Test
    void testImportFromCSV_InvalidHeader() {
        String csv = "WRONG,HEADER\nNSE,TEST\n";
        MockMultipartFile file = new MockMultipartFile("file", "test.csv", "text/csv", csv.getBytes());
        Map<String, Object> result = portfolioService.importFromCSV(file);
        assertFalse((Boolean) result.get("success"));
    }
}
TESTEOF
    print_success "Created PortfolioServiceTest.java (3 tests)"
    
    # TradeControllerIntegrationTest (3 tests)
    cat > src/test/java/com/stockmarket/controller/TradeControllerIntegrationTest.java << 'TESTEOF'
package com.stockmarket.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.stockmarket.dto.TradeRequest;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class TradeControllerIntegrationTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private TradeRepository tradeRepository;
    @Autowired private PortfolioRepository portfolioRepository;

    @BeforeEach
    void setUp() {
        tradeRepository.deleteAll();
        portfolioRepository.deleteAll();
    }

    @Test
    void testExecuteTrade_BuyOrder() throws Exception {
        TradeRequest request = new TradeRequest();
        request.setTickerId("RELIANCE.NS");
        request.setCompanyName("Reliance");
        request.setTradeType("BUY");
        request.setQuantity(10);
        request.setPrice(2850.50);
        request.setTotalAmount(28505.00);
        mockMvc.perform(post("/api/trades")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("SUCCESS"));
    }

    @Test
    void testGetAllTrades() throws Exception {
        mockMvc.perform(get("/api/trades"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void testGetPortfolio() throws Exception {
        Portfolio p = new Portfolio();
        p.setTickerId("RELIANCE.NS");
        p.setTotalQuantity(10);
        p.setAveragePrice(2850.50);
        p.setCreatedAt(LocalDateTime.now());
        p.setLastUpdated(LocalDateTime.now());
        portfolioRepository.save(p);
        mockMvc.perform(get("/api/trades/portfolio"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }
}
TESTEOF
    print_success "Created TradeControllerIntegrationTest.java (3 tests)"
}

create_github_workflow() {
    print_header "Creating GitHub Actions Workflow"
    
    cat > .github/workflows/ci-cd.yml << 'WORKFLOWEOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: maven
    - name: Create test config
      run: |
        mkdir -p src/main/resources
        echo "server.port=8080" > src/main/resources/application-test.properties
        echo "spring.datasource.url=jdbc:h2:mem:testdb" >> src/main/resources/application-test.properties
        echo "spring.datasource.driverClassName=org.h2.Driver" >> src/main/resources/application-test.properties
        echo "spring.jpa.hibernate.ddl-auto=create-drop" >> src/main/resources/application-test.properties
        echo "stock.api.key=test-key" >> src/main/resources/application-test.properties
        echo "gemini.api.key=test-key" >> src/main/resources/application-test.properties
    - name: Run tests
      run: mvn clean test -Dspring.profiles.active=test
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: target/surefire-reports/

  build:
    name: Build
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: maven
    - name: Build
      run: mvn clean package -DskipTests
    - name: Upload JAR
      uses: actions/upload-artifact@v4
      with:
        name: application-jar
        path: target/*.jar
WORKFLOWEOF
    
    print_success "Created .github/workflows/ci-cd.yml"
}

create_configs() {
    print_header "Creating Configuration Files"
    
    # .gitignore
    cat > .gitignore << 'GITIGNOREEOF'
*.class
target/
.idea/
*.iml
.vscode/
.env
.env.local
application-production.properties
*.log
.DS_Store
*.db
*.h2.db
GITIGNOREEOF
    print_success "Created .gitignore"
    
    # .env.template
    cat > .env.template << 'ENVEOF'
# Copy to .env and fill in values
STOCK_API_KEY=your-key-here
GEMINI_API_KEY=your-key-here
MYSQL_PASSWORD=your-password-here
ENVEOF
    print_success "Created .env.template"
    
    # Quick Start Guide
    cat > docs/QUICK_START.md << 'DOCEOF'
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
DOCEOF
    print_success "Created docs/QUICK_START.md"
}

run_tests() {
    print_header "Running Tests"
    
    if mvn clean test -Dspring.profiles.active=test 2>&1 | tee test_output.log; then
        print_success "All 9 tests passed! ✓"
        rm -f test_output.log
        return 0
    else
        print_warning "Some tests may have failed. Check test_output.log"
        return 1
    fi
}

print_summary() {
    print_header "Setup Complete! 🎉"
    
    cat << 'SUMMARYEOF'
✅ Files Created:
   - .github/workflows/ci-cd.yml
   - src/test/.../TradeServiceTest.java (3 tests)
   - src/test/.../PortfolioServiceTest.java (3 tests)
   - src/test/.../TradeControllerIntegrationTest.java (3 tests)
   - .gitignore
   - .env.template
   - docs/QUICK_START.md

📊 Total: 9 test cases

🔐 Next: Add GitHub Secrets
   1. Go to: Settings → Secrets → Actions
   2. Add: STOCK_API_KEY, GEMINI_API_KEY, MYSQL_PASSWORD
   3. Push: git push origin main
   4. Check: Actions tab

📖 See: docs/QUICK_START.md
SUMMARYEOF
}

main() {
    clear
    echo "╔══════════════════════════════════════════╗"
    echo "║  GitHub Actions Setup - Stock Platform  ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    create_directory_structure
    create_test_files
    create_github_workflow
    create_configs
    
    read -p "Run tests now? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && run_tests
    
    print_summary
}

main "$@"