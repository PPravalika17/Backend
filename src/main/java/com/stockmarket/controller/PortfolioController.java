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
