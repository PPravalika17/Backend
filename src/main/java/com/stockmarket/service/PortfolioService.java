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
