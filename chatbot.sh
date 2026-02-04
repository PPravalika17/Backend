#!/bin/bash

# Stock Market App - Portfolio Import/Export Feature
# This script adds CSV import/export functionality to the portfolio

set -e  # Exit on error

echo "============================================"
echo "Portfolio Import/Export Feature Installation"
echo "============================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current directory
CURRENT_DIR=$(pwd)
echo "Working directory: $CURRENT_DIR"

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}Error: pom.xml not found. Please run this script from the project root directory.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found pom.xml - correct directory${NC}"

echo -e "${YELLOW}Step 1: Creating backup directory...${NC}"
BACKUP_DIR="backups/portfolio_import_export_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing files
if [ -f "src/main/java/com/stockmarket/controller/PortfolioController.java" ]; then
    cp "src/main/java/com/stockmarket/controller/PortfolioController.java" "$BACKUP_DIR/" 2>/dev/null || true
fi
if [ -f "src/main/java/com/stockmarket/service/PortfolioService.java" ]; then
    cp "src/main/java/com/stockmarket/service/PortfolioService.java" "$BACKUP_DIR/" 2>/dev/null || true
fi
if [ -f "src/main/resources/static/app.js" ]; then
    cp "src/main/resources/static/app.js" "$BACKUP_DIR/" 2>/dev/null || true
fi
if [ -f "src/main/resources/static/index.html" ]; then
    cp "src/main/resources/static/index.html" "$BACKUP_DIR/" 2>/dev/null || true
fi

echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"

# ============================================
# Step 2: Create PortfolioController.java
# ============================================
echo -e "${YELLOW}Step 2: Creating PortfolioController.java...${NC}"

mkdir -p "src/main/java/com/stockmarket/controller"

cat > "src/main/java/com/stockmarket/controller/PortfolioController.java" << 'PORTFOLIOCONTROLLER_EOF'
package com.stockmarket.controller;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.service.PortfolioService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/portfolio")
@CrossOrigin(origins = "*")
public class PortfolioController {
    
    @Autowired
    private PortfolioService portfolioService;
    
    /**
     * Export portfolio to CSV
     * Format: EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP
     */
    @GetMapping("/export")
    public void exportPortfolio(HttpServletResponse response) throws IOException {
        response.setContentType("text/csv");
        response.setHeader("Content-Disposition", 
            "attachment; filename=portfolio_" + 
            LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".csv");
        
        PrintWriter writer = response.getWriter();
        
        // Write CSV header
        writer.println("EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP");
        
        // Get all portfolio items
        List<Portfolio> portfolioList = portfolioService.getAllPortfolio();
        
        if (portfolioList.isEmpty()) {
            writer.println("# Portfolio is empty");
        } else {
            for (Portfolio portfolio : portfolioList) {
                // Determine exchange from ticker symbol
                String exchange = portfolio.getTickerId().contains(".NS") ? "NSE" : "BSE";
                
                // Format timestamp
                String timestamp = portfolio.getLastUpdated() != null 
                    ? portfolio.getLastUpdated().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                    : LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                
                // Write CSV row
                writer.printf("%s,%s,\"%s\",%d,%.2f,%s%n",
                    exchange,
                    portfolio.getTickerId(),
                    portfolio.getCompanyName(),
                    portfolio.getTotalQuantity(),
                    portfolio.getAveragePrice(),
                    timestamp
                );
            }
        }
        
        writer.flush();
    }
    
    /**
     * Import portfolio from CSV
     * Expected format: EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP
     */
    @PostMapping("/import")
    public ResponseEntity<Map<String, Object>> importPortfolio(@RequestParam("file") MultipartFile file) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Validate file
            if (file.isEmpty()) {
                response.put("success", false);
                response.put("message", "File is empty");
                return ResponseEntity.badRequest().body(response);
            }
            
            if (!file.getOriginalFilename().endsWith(".csv")) {
                response.put("success", false);
                response.put("message", "Only CSV files are allowed");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Process CSV
            Map<String, Object> result = portfolioService.importFromCSV(file);
            
            if ((boolean) result.get("success")) {
                response.put("success", true);
                response.put("message", result.get("message"));
                response.put("imported", result.get("imported"));
                response.put("skipped", result.get("skipped"));
                response.put("errors", result.get("errors"));
                return ResponseEntity.ok(response);
            } else {
                response.put("success", false);
                response.put("message", result.get("message"));
                response.put("errors", result.get("errors"));
                return ResponseEntity.badRequest().body(response);
            }
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error importing portfolio: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}
PORTFOLIOCONTROLLER_EOF

echo -e "${GREEN}✓ PortfolioController.java created${NC}"

# ============================================
# Step 3: Create PortfolioService.java
# ============================================
echo -e "${YELLOW}Step 3: Creating PortfolioService.java...${NC}"

mkdir -p "src/main/java/com/stockmarket/service"

cat > "src/main/java/com/stockmarket/service/PortfolioService.java" << 'PORTFOLIOSERVICE_EOF'
package com.stockmarket.service;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.PortfolioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class PortfolioService {
    
    @Autowired
    private PortfolioRepository portfolioRepository;
    
    public List<Portfolio> getAllPortfolio() {
        return portfolioRepository.findAll();
    }
    
    @Transactional
    public Map<String, Object> importFromCSV(MultipartFile file) {
        Map<String, Object> result = new HashMap<>();
        List<String> errors = new ArrayList<>();
        int importedCount = 0;
        int skippedCount = 0;
        
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream()));
            String line;
            int lineNumber = 0;
            
            // Read header
            line = reader.readLine();
            lineNumber++;
            
            if (line == null) {
                result.put("success", false);
                result.put("message", "File is empty");
                result.put("errors", Collections.singletonList("File contains no data"));
                return result;
            }
            
            // Validate header
            String expectedHeader = "EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP";
            String actualHeader = line.trim().toUpperCase();
            
            if (!actualHeader.equals(expectedHeader)) {
                result.put("success", false);
                result.put("message", "Invalid CSV format. Expected header: " + expectedHeader);
                errors.add("Line 1: Invalid header format");
                errors.add("Expected: " + expectedHeader);
                errors.add("Found: " + actualHeader);
                result.put("errors", errors);
                return result;
            }
            
            // Process data rows
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                line = line.trim();
                
                // Skip empty lines and comments
                if (line.isEmpty() || line.startsWith("#")) {
                    skippedCount++;
                    continue;
                }
                
                try {
                    // Parse CSV line (handle quoted values)
                    List<String> values = parseCSVLine(line);
                    
                    if (values.size() != 6) {
                        errors.add("Line " + lineNumber + ": Invalid number of columns. Expected 6, found " + values.size());
                        skippedCount++;
                        continue;
                    }
                    
                    // Extract values
                    String exchange = values.get(0).trim();
                    String symbol = values.get(1).trim();
                    String name = values.get(2).trim();
                    String quantityStr = values.get(3).trim();
                    String priceStr = values.get(4).trim();
                    String timestampStr = values.get(5).trim();
                    
                    // Validate exchange
                    if (!exchange.equals("NSE") && !exchange.equals("BSE")) {
                        errors.add("Line " + lineNumber + ": Invalid exchange '" + exchange + "'. Must be NSE or BSE");
                        skippedCount++;
                        continue;
                    }
                    
                    // Validate and parse quantity
                    int quantity;
                    try {
                        quantity = Integer.parseInt(quantityStr);
                        if (quantity <= 0) {
                            errors.add("Line " + lineNumber + ": Quantity must be positive");
                            skippedCount++;
                            continue;
                        }
                    } catch (NumberFormatException e) {
                        errors.add("Line " + lineNumber + ": Invalid quantity '" + quantityStr + "'");
                        skippedCount++;
                        continue;
                    }
                    
                    // Validate and parse price
                    double price;
                    try {
                        price = Double.parseDouble(priceStr);
                        if (price <= 0) {
                            errors.add("Line " + lineNumber + ": Price must be positive");
                            skippedCount++;
                            continue;
                        }
                    } catch (NumberFormatException e) {
                        errors.add("Line " + lineNumber + ": Invalid price '" + priceStr + "'");
                        skippedCount++;
                        continue;
                    }
                    
                    // Parse timestamp
                    LocalDateTime timestamp;
                    try {
                        timestamp = LocalDateTime.parse(timestampStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                    } catch (Exception e) {
                        // Use current time if timestamp is invalid
                        timestamp = LocalDateTime.now();
                    }
                    
                    // Check if portfolio entry already exists
                    Optional<Portfolio> existingPortfolio = portfolioRepository.findByTickerId(symbol);
                    
                    if (existingPortfolio.isPresent()) {
                        // Update existing portfolio
                        Portfolio portfolio = existingPortfolio.get();
                        
                        // Calculate new average price
                        double totalCost = (portfolio.getTotalQuantity() * portfolio.getAveragePrice()) + 
                                         (quantity * price);
                        int newTotalQuantity = portfolio.getTotalQuantity() + quantity;
                        double newAveragePrice = totalCost / newTotalQuantity;
                        
                        portfolio.setTotalQuantity(newTotalQuantity);
                        portfolio.setAveragePrice(newAveragePrice);
                        portfolio.setCurrentValue(newTotalQuantity * price);
                        portfolio.setLastUpdated(timestamp);
                        
                        portfolioRepository.save(portfolio);
                    } else {
                        // Create new portfolio entry
                        Portfolio newPortfolio = new Portfolio();
                        newPortfolio.setTickerId(symbol);
                        newPortfolio.setCompanyName(name);
                        newPortfolio.setTotalQuantity(quantity);
                        newPortfolio.setAveragePrice(price);
                        newPortfolio.setCurrentValue(quantity * price);
                        newPortfolio.setCreatedAt(timestamp);
                        newPortfolio.setLastUpdated(timestamp);
                        
                        portfolioRepository.save(newPortfolio);
                    }
                    
                    importedCount++;
                    
                } catch (Exception e) {
                    errors.add("Line " + lineNumber + ": Error processing line - " + e.getMessage());
                    skippedCount++;
                }
            }
            
            reader.close();
            
            // Build result
            result.put("success", true);
            result.put("message", String.format("Import completed. Imported: %d, Skipped: %d", 
                                                importedCount, skippedCount));
            result.put("imported", importedCount);
            result.put("skipped", skippedCount);
            result.put("errors", errors);
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Error reading CSV file: " + e.getMessage());
            result.put("errors", Collections.singletonList(e.getMessage()));
        }
        
        return result;
    }
    
    /**
     * Parse CSV line handling quoted values
     */
    private List<String> parseCSVLine(String line) {
        List<String> values = new ArrayList<>();
        StringBuilder currentValue = new StringBuilder();
        boolean inQuotes = false;
        
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                values.add(currentValue.toString());
                currentValue = new StringBuilder();
            } else {
                currentValue.append(c);
            }
        }
        
        values.add(currentValue.toString());
        return values;
    }
}
PORTFOLIOSERVICE_EOF

echo -e "${GREEN}✓ PortfolioService.java created${NC}"

# ============================================
# Step 4: Update app.js with Import/Export functions
# ============================================
echo -e "${YELLOW}Step 4: Adding Import/Export functions to app.js...${NC}"

if [ ! -f "src/main/resources/static/app.js" ]; then
    echo -e "${RED}Error: app.js not found${NC}"
    exit 1
fi

# Add import/export functions to app.js
cat >> "src/main/resources/static/app.js" << 'APPJS_ADDITION'

// ============================================
// PORTFOLIO IMPORT/EXPORT FUNCTIONS
// ============================================

/**
 * Export portfolio to CSV
 */
async function exportPortfolio() {
    try {
        const response = await fetch(`${BACKEND_API}/portfolio/export`);
        
        if (!response.ok) {
            throw new Error('Failed to export portfolio');
        }
        
        // Get the blob data
        const blob = await response.blob();
        
        // Create download link
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `portfolio_${new Date().toISOString().split('T')[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        
        // Cleanup
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
        showToast('success', 'Portfolio exported successfully!');
        
    } catch (error) {
        console.error('Export error:', error);
        showToast('error', 'Failed to export portfolio');
    }
}

/**
 * Open import portfolio modal
 */
function openImportPortfolioModal() {
    document.getElementById('importPortfolioModal').classList.add('active');
    // Reset file input
    const fileInput = document.getElementById('portfolioFileInput');
    if (fileInput) {
        fileInput.value = '';
    }
    // Clear any previous messages
    const messageDiv = document.getElementById('importMessage');
    if (messageDiv) {
        messageDiv.innerHTML = '';
        messageDiv.style.display = 'none';
    }
}

/**
 * Close import portfolio modal
 */
function closeImportPortfolioModal() {
    document.getElementById('importPortfolioModal').classList.remove('active');
}

/**
 * Import portfolio from CSV
 */
async function importPortfolio() {
    const fileInput = document.getElementById('portfolioFileInput');
    const messageDiv = document.getElementById('importMessage');
    
    if (!fileInput.files || fileInput.files.length === 0) {
        messageDiv.innerHTML = '<div class="import-error">⚠️ Please select a CSV file</div>';
        messageDiv.style.display = 'block';
        return;
    }
    
    const file = fileInput.files[0];
    
    // Validate file extension
    if (!file.name.endsWith('.csv')) {
        messageDiv.innerHTML = '<div class="import-error">⚠️ Only CSV files are allowed</div>';
        messageDiv.style.display = 'block';
        return;
    }
    
    // Show loading
    messageDiv.innerHTML = '<div class="import-loading">📤 Importing portfolio...</div>';
    messageDiv.style.display = 'block';
    
    try {
        const formData = new FormData();
        formData.append('file', file);
        
        const response = await fetch(`${BACKEND_API}/portfolio/import`, {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            let message = `<div class="import-success">✅ ${result.message}</div>`;
            
            if (result.errors && result.errors.length > 0) {
                message += '<div class="import-warnings"><strong>Warnings:</strong><ul>';
                result.errors.slice(0, 5).forEach(error => {
                    message += `<li>${error}</li>`;
                });
                if (result.errors.length > 5) {
                    message += `<li>... and ${result.errors.length - 5} more</li>`;
                }
                message += '</ul></div>';
            }
            
            messageDiv.innerHTML = message;
            showToast('success', `Imported ${result.imported} stocks successfully!`);
            
            // Reload portfolio after 2 seconds
            setTimeout(() => {
                closeImportPortfolioModal();
                if (currentTab === 'portfolio') {
                    loadPortfolio();
                }
            }, 2000);
            
        } else {
            let errorMessage = `<div class="import-error">❌ ${result.message}</div>`;
            
            if (result.errors && result.errors.length > 0) {
                errorMessage += '<div class="import-error-details"><strong>Errors:</strong><ul>';
                result.errors.slice(0, 10).forEach(error => {
                    errorMessage += `<li>${error}</li>`;
                });
                if (result.errors.length > 10) {
                    errorMessage += `<li>... and ${result.errors.length - 10} more</li>`;
                }
                errorMessage += '</ul></div>';
            }
            
            messageDiv.innerHTML = errorMessage;
            showToast('error', 'Import failed. Please check the file format.');
        }
        
    } catch (error) {
        console.error('Import error:', error);
        messageDiv.innerHTML = `<div class="import-error">❌ Error importing portfolio: ${error.message}</div>`;
        messageDiv.style.display = 'block';
        showToast('error', 'Failed to import portfolio');
    }
}

/**
 * Download sample CSV template
 */
function downloadSampleCSV() {
    const sampleData = `EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP
NSE,RELIANCE.NS,"Reliance Industries Ltd",10,2850.50,2026-02-04T10:30:00
BSE,TCS.BO,"Tata Consultancy Services",5,3685.75,2026-02-04T11:15:00
NSE,INFY.NS,"Infosys Limited",15,1520.25,2026-02-04T14:20:00`;
    
    const blob = new Blob([sampleData], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'portfolio_template.csv';
    document.body.appendChild(a);
    a.click();
    
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
    
    showToast('success', 'Sample CSV template downloaded!');
}
APPJS_ADDITION

echo -e "${GREEN}✓ app.js updated with import/export functions${NC}"

# ============================================
# Step 5: Add Import/Export buttons and modal to index.html
# ============================================
echo -e "${YELLOW}Step 5: Adding Import/Export UI to index.html...${NC}"

if [ ! -f "src/main/resources/static/index.html" ]; then
    echo -e "${RED}Error: index.html not found${NC}"
    exit 1
fi

# Create styles for import/export
cat > "/tmp/import_export_styles.css" << 'IMPORTEXPORT_STYLES'

        /* Import/Export Buttons */
        .portfolio-actions {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .action-btn {
            padding: 12px 25px;
            border: none;
            border-radius: 10px;
            font-size: 1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-export {
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: white;
        }

        .btn-export:hover {
            background: linear-gradient(135deg, #2980b9 0%, #21618c 100%);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(52, 152, 219, 0.3);
        }

        .btn-import {
            background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%);
            color: white;
        }

        .btn-import:hover {
            background: linear-gradient(135deg, #8e44ad 0%, #7d3c98 100%);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(155, 89, 182, 0.3);
        }

        /* Import Modal Specific Styles */
        .import-info-box {
            background: rgba(52, 152, 219, 0.1);
            border: 2px solid #3498db;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 25px;
        }

        .import-info-title {
            color: #3498db;
            font-weight: bold;
            font-size: 1.1em;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .import-format-list {
            color: #e0e0e0;
            line-height: 2;
            margin-left: 20px;
        }

        .import-format-list li {
            margin: 8px 0;
        }

        .import-format-list code {
            background: #1a1d2e;
            padding: 2px 8px;
            border-radius: 4px;
            color: #5cb85c;
            font-family: 'Courier New', monospace;
        }

        .warning-box {
            background: rgba(241, 196, 15, 0.1);
            border: 2px solid #f1c40f;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
            color: #f1c40f;
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }

        .warning-icon {
            font-size: 1.5em;
            flex-shrink: 0;
        }

        .file-input-wrapper {
            position: relative;
            margin: 20px 0;
        }

        .file-input-label {
            display: block;
            padding: 40px 20px;
            background: #252a3d;
            border: 2px dashed #2d3447;
            border-radius: 12px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }

        .file-input-label:hover {
            border-color: #5cb85c;
            background: #2d3447;
        }

        .file-input-label.has-file {
            border-color: #5cb85c;
            background: rgba(92, 184, 92, 0.1);
        }

        .file-input {
            display: none;
        }

        .file-input-text {
            color: #8a92a6;
            font-size: 1em;
        }

        .file-input-text.has-file {
            color: #5cb85c;
            font-weight: 600;
        }

        .file-icon {
            font-size: 3em;
            margin-bottom: 15px;
        }

        .sample-download-btn {
            margin-top: 15px;
            padding: 10px 20px;
            background: #2d3447;
            color: #3498db;
            border: 2px solid #3498db;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }

        .sample-download-btn:hover {
            background: #3498db;
            color: white;
        }

        #importMessage {
            margin-top: 20px;
            padding: 15px;
            border-radius: 8px;
            display: none;
        }

        .import-success {
            background: rgba(46, 204, 113, 0.1);
            border: 1px solid #2ecc71;
            color: #2ecc71;
            padding: 12px;
            border-radius: 8px;
        }

        .import-error {
            background: rgba(231, 76, 60, 0.1);
            border: 1px solid #e74c3c;
            color: #e74c3c;
            padding: 12px;
            border-radius: 8px;
        }

        .import-loading {
            background: rgba(52, 152, 219, 0.1);
            border: 1px solid #3498db;
            color: #3498db;
            padding: 12px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .import-warnings {
            margin-top: 15px;
            padding: 12px;
            background: rgba(241, 196, 15, 0.1);
            border: 1px solid #f1c40f;
            color: #f1c40f;
            border-radius: 8px;
            font-size: 0.9em;
        }

        .import-warnings ul {
            margin-top: 8px;
            margin-left: 20px;
        }

        .import-warnings li {
            margin: 5px 0;
        }

        .import-error-details {
            margin-top: 15px;
            padding: 12px;
            background: rgba(231, 76, 60, 0.05);
            border-radius: 8px;
            font-size: 0.9em;
            max-height: 200px;
            overflow-y: auto;
        }

        .import-error-details ul {
            margin-top: 8px;
            margin-left: 20px;
        }

        .import-error-details li {
            margin: 5px 0;
        }
IMPORTEXPORT_STYLES

# Create import modal HTML
cat > "/tmp/import_modal.html" << 'IMPORT_MODAL'

    <!-- Import Portfolio Modal -->
    <div id="importPortfolioModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 class="modal-title">📥 Import Portfolio</h2>
                <button class="close-btn" onclick="closeImportPortfolioModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="import-info-box">
                    <div class="import-info-title">📋 CSV Format Requirements</div>
                    <ul class="import-format-list">
                        <li><strong>Header:</strong> <code>EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP</code></li>
                        <li><strong>EXCHANGE:</strong> Must be either <code>NSE</code> or <code>BSE</code></li>
                        <li><strong>SYMBOL:</strong> Stock ticker symbol (e.g., RELIANCE.NS, TCS.BO)</li>
                        <li><strong>NAME:</strong> Company name (use quotes if contains commas)</li>
                        <li><strong>QUANTITY:</strong> Number of shares (positive integer)</li>
                        <li><strong>PRICE:</strong> Purchase price per share (positive decimal)</li>
                        <li><strong>TIMESTAMP:</strong> ISO format (e.g., 2026-02-04T10:30:00)</li>
                    </ul>
                </div>

                <div class="warning-box">
                    <span class="warning-icon">⚠️</span>
                    <div>
                        <strong>Important:</strong> The CSV file must have exactly these columns in this order. 
                        Any format mismatch will result in an error. Existing portfolio entries will be updated 
                        (quantities added, prices averaged).
                    </div>
                </div>

                <div class="file-input-wrapper">
                    <label for="portfolioFileInput" class="file-input-label" id="fileInputLabel">
                        <div class="file-icon">📄</div>
                        <div class="file-input-text" id="fileInputText">
                            Click to select CSV file or drag and drop here
                        </div>
                    </label>
                    <input type="file" 
                           id="portfolioFileInput" 
                           class="file-input" 
                           accept=".csv"
                           onchange="handleFileSelect(this)">
                </div>

                <div style="text-align: center;">
                    <button class="sample-download-btn" onclick="downloadSampleCSV()">
                        📥 Download Sample CSV Template
                    </button>
                </div>

                <div id="importMessage"></div>

                <div class="modal-actions">
                    <button class="btn btn-cancel" onclick="closeImportPortfolioModal()">Cancel</button>
                    <button class="btn btn-confirm" 
                            style="background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%);"
                            onclick="importPortfolio()">
                        Import Portfolio
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script>
        function handleFileSelect(input) {
            const label = document.getElementById('fileInputLabel');
            const text = document.getElementById('fileInputText');
            
            if (input.files && input.files.length > 0) {
                const fileName = input.files[0].name;
                text.textContent = `Selected: ${fileName}`;
                text.classList.add('has-file');
                label.classList.add('has-file');
            } else {
                text.textContent = 'Click to select CSV file or drag and drop here';
                text.classList.remove('has-file');
                label.classList.remove('has-file');
            }
        }
    </script>
IMPORT_MODAL

# Insert styles before </style>
sed -i '/<\/style>/e cat /tmp/import_export_styles.css' "src/main/resources/static/index.html"

# Insert modal before </body>
sed -i '/<\/body>/e cat /tmp/import_modal.html' "src/main/resources/static/index.html"

# Add action buttons to portfolio tab (after the portfolio header)
# This is a bit tricky, we'll need to add it programmatically
cat > "/tmp/add_portfolio_actions.sh" << 'ADD_ACTIONS_SCRIPT'
#!/bin/bash

# Find the line with "Portfolio Tab" and add action buttons after the header
sed -i '/<div id="portfolioTab" class="tab-content">/,/<\/div>/ {
    /<div class="content-header">/,/<\/div>/ {
        /<\/div>/a\
\
            <div class="portfolio-actions">\
                <button class="action-btn btn-export" onclick="exportPortfolio()">\
                    <span>📤</span> Export Portfolio\
                </button>\
                <button class="action-btn btn-import" onclick="openImportPortfolioModal()">\
                    <span>📥</span> Import Portfolio\
                </button>\
            </div>
    }
}' "src/main/resources/static/index.html"
ADD_ACTIONS_SCRIPT

chmod +x /tmp/add_portfolio_actions.sh
/tmp/add_portfolio_actions.sh

# Cleanup temp files
rm -f /tmp/import_export_styles.css /tmp/import_modal.html /tmp/add_portfolio_actions.sh

echo -e "${GREEN}✓ index.html updated with Import/Export UI${NC}"

# ============================================
# Step 6: Update pom.xml if needed
# ============================================
echo -e "${YELLOW}Step 6: Verifying dependencies in pom.xml...${NC}"

if grep -q "commons-csv" "pom.xml"; then
    echo -e "${GREEN}✓ Apache Commons CSV dependency already exists${NC}"
else
    echo -e "${YELLOW}⚠ Note: For enhanced CSV parsing, consider adding Apache Commons CSV dependency${NC}"
    echo -e "${YELLOW}  Add this to your pom.xml <dependencies> section:${NC}"
    echo ""
    echo "    <dependency>"
    echo "        <groupId>org.apache.commons</groupId>"
    echo "        <artifactId>commons-csv</artifactId>"
    echo "        <version>1.10.0</version>"
    echo "    </dependency>"
    echo ""
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✓ Portfolio Import/Export Feature Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Summary of Changes:${NC}"
echo "1. ✓ PortfolioController.java - Created with export and import endpoints"
echo "2. ✓ PortfolioService.java - Created with CSV import logic and validation"
echo "3. ✓ app.js - Added import/export functions"
echo "4. ✓ index.html - Added Import/Export buttons and modal"
echo "5. ✓ Backups created at: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}CSV Format:${NC}"
echo "EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP"
echo "NSE,RELIANCE.NS,\"Reliance Industries Ltd\",10,2850.50,2026-02-04T10:30:00"
echo ""
echo -e "${YELLOW}Features:${NC}"
echo "📤 Export - Download portfolio as CSV"
echo "📥 Import - Upload CSV to add/update portfolio"
echo "⚠️  Format Validation - Strict CSV format checking"
echo "📋 Sample Template - Download example CSV"
echo "🔄 Smart Updates - Existing stocks updated (quantities added, prices averaged)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Rebuild: mvn clean install"
echo "2. Run: mvn spring-boot:run"
echo "3. Navigate to Portfolio tab"
echo "4. Use Export/Import buttons"
echo ""
echo -e "${BLUE}Test the Import Feature:${NC}"
echo "1. Click 'Download Sample CSV Template'"
echo "2. Edit the CSV file with your stocks"
echo "3. Click 'Import Portfolio' and select the file"
echo ""