package com.stockmarket.controller;

import com.stockmarket.dto.TradeRequest;
import com.stockmarket.dto.TradeResponse;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.service.TradeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/trades")
@CrossOrigin(origins = "*")
public class TradeController {
    
    @Autowired
    private TradeService tradeService;
    
    @PostMapping
    public ResponseEntity<TradeResponse> executeTrade(@RequestBody TradeRequest request) {
        try {
            TradeResponse response = tradeService.executeTrade(request);
            
            if ("SUCCESS".equals(response.getStatus())) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (Exception e) {
            TradeResponse errorResponse = new TradeResponse("ERROR", "Failed to execute trade: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    @GetMapping
    public ResponseEntity<List<Trade>> getAllTrades() {
        try {
            List<Trade> trades = tradeService.getAllTrades();
            return ResponseEntity.ok(trades);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Trade> getTradeById(@PathVariable Long id) {
        try {
            Optional<Trade> trade = tradeService.getTradeById(id);
            return trade.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/ticker/{tickerId}")
    public ResponseEntity<List<Trade>> getTradesByTicker(@PathVariable String tickerId) {
        try {
            List<Trade> trades = tradeService.getTradesByTicker(tickerId);
            return ResponseEntity.ok(trades);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTrade(@PathVariable Long id) {
        try {
            boolean deleted = tradeService.deleteTrade(id);
            if (deleted) {
                return ResponseEntity.noContent().build();
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/portfolio")
    public ResponseEntity<List<Portfolio>> getPortfolio() {
        try {
            List<Portfolio> portfolio = tradeService.getPortfolio();
            return ResponseEntity.ok(portfolio);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/portfolio/{tickerId}")
    public ResponseEntity<Portfolio> getPortfolioByTicker(@PathVariable String tickerId) {
        try {
            Optional<Portfolio> portfolio = tradeService.getPortfolioByTicker(tickerId);
            return portfolio.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
