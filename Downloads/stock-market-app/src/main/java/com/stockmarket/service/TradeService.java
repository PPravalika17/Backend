package com.stockmarket.service;

import com.stockmarket.dto.TradeRequest;
import com.stockmarket.dto.TradeResponse;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.repository.TradeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class TradeService {
    
    @Autowired
    private TradeRepository tradeRepository;
    
    @Autowired
    private PortfolioRepository portfolioRepository;
    
    @Transactional
    public TradeResponse executeTrade(TradeRequest request) {
        try {
            if (request.getTickerId() == null || request.getTickerId().isEmpty()) {
                return new TradeResponse("ERROR", "Ticker ID is required");
            }
            
            if (request.getTradeType() == null || 
                (!request.getTradeType().equals("BUY") && !request.getTradeType().equals("SELL"))) {
                return new TradeResponse("ERROR", "Trade type must be BUY or SELL");
            }
            
            if (request.getQuantity() == null || request.getQuantity() <= 0) {
                return new TradeResponse("ERROR", "Quantity must be greater than 0");
            }
            
            if (request.getPrice() == null || request.getPrice() <= 0) {
                return new TradeResponse("ERROR", "Price must be greater than 0");
            }
            
            Trade trade = new Trade();
            trade.setTickerId(request.getTickerId());
            trade.setCompanyName(request.getCompanyName());
            trade.setTradeType(request.getTradeType());
            trade.setQuantity(request.getQuantity());
            trade.setPrice(request.getPrice());
            trade.setTotalAmount(request.getTotalAmount());
            trade.setDate(request.getDate());
            trade.setTime(request.getTime());
            trade.setTimestamp(LocalDateTime.now());
            
            Trade savedTrade = tradeRepository.save(trade);
            
            if ("BUY".equals(request.getTradeType())) {
                updatePortfolioForBuy(request);
            } else if ("SELL".equals(request.getTradeType())) {
                boolean success = updatePortfolioForSell(request);
                if (!success) {
                    return new TradeResponse("ERROR", "Insufficient shares to sell");
                }
            }
            
            TradeResponse response = new TradeResponse();
            response.setId(savedTrade.getId());
            response.setTickerId(savedTrade.getTickerId());
            response.setCompanyName(savedTrade.getCompanyName());
            response.setTradeType(savedTrade.getTradeType());
            response.setQuantity(savedTrade.getQuantity());
            response.setPrice(savedTrade.getPrice());
            response.setTotalAmount(savedTrade.getTotalAmount());
            response.setDate(savedTrade.getDate());
            response.setTime(savedTrade.getTime());
            response.setTimestamp(savedTrade.getTimestamp());
            response.setStatus("SUCCESS");
            response.setMessage(request.getTradeType() + " order executed successfully");
            
            return response;
            
        } catch (Exception e) {
            return new TradeResponse("ERROR", "Failed to execute trade: " + e.getMessage());
        }
    }
    
    private void updatePortfolioForBuy(TradeRequest request) {
        Optional<Portfolio> existingPortfolio = portfolioRepository.findByTickerId(request.getTickerId());
        
        if (existingPortfolio.isPresent()) {
            Portfolio portfolio = existingPortfolio.get();
            double totalCost = (portfolio.getTotalQuantity() * portfolio.getAveragePrice()) + 
                              (request.getQuantity() * request.getPrice());
            int newTotalQuantity = portfolio.getTotalQuantity() + request.getQuantity();
            double newAveragePrice = totalCost / newTotalQuantity;
            
            portfolio.setTotalQuantity(newTotalQuantity);
            portfolio.setAveragePrice(newAveragePrice);
            portfolio.setCurrentValue(newTotalQuantity * request.getPrice());
            portfolio.setLastUpdated(LocalDateTime.now());
            
            portfolioRepository.save(portfolio);
        } else {
            Portfolio newPortfolio = new Portfolio();
            newPortfolio.setTickerId(request.getTickerId());
            newPortfolio.setCompanyName(request.getCompanyName());
            newPortfolio.setTotalQuantity(request.getQuantity());
            newPortfolio.setAveragePrice(request.getPrice());
            newPortfolio.setCurrentValue(request.getTotalAmount());
            newPortfolio.setLastUpdated(LocalDateTime.now());
            
            portfolioRepository.save(newPortfolio);
        }
    }
    
    private boolean updatePortfolioForSell(TradeRequest request) {
        Optional<Portfolio> existingPortfolio = portfolioRepository.findByTickerId(request.getTickerId());
        
        if (existingPortfolio.isPresent()) {
            Portfolio portfolio = existingPortfolio.get();
            
            if (portfolio.getTotalQuantity() < request.getQuantity()) {
                return false;
            }
            
            int newQuantity = portfolio.getTotalQuantity() - request.getQuantity();
            
            if (newQuantity == 0) {
                portfolioRepository.delete(portfolio);
            } else {
                portfolio.setTotalQuantity(newQuantity);
                portfolio.setCurrentValue(newQuantity * request.getPrice());
                portfolio.setLastUpdated(LocalDateTime.now());
                portfolioRepository.save(portfolio);
            }
            
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * NEW METHOD: Sell shares from portfolio with quantity selection
     * This method creates a SELL trade and updates the portfolio accordingly
     */
    @Transactional
    public TradeResponse sellFromPortfolio(String tickerId, int quantity, double currentPrice) {
        try {
            // Validate portfolio existence
            Optional<Portfolio> portfolioOpt = portfolioRepository.findByTickerId(tickerId);
            if (!portfolioOpt.isPresent()) {
                return new TradeResponse("ERROR", "Stock not found in portfolio");
            }
            
            Portfolio portfolio = portfolioOpt.get();
            
            // Validate quantity
            if (quantity <= 0) {
                return new TradeResponse("ERROR", "Quantity must be greater than 0");
            }
            
            if (quantity > portfolio.getTotalQuantity()) {
                return new TradeResponse("ERROR", "Insufficient shares. You own only " + 
                                        portfolio.getTotalQuantity() + " shares");
            }
            
            // Create SELL trade request
            TradeRequest sellRequest = new TradeRequest();
            sellRequest.setTickerId(tickerId);
            sellRequest.setCompanyName(portfolio.getCompanyName());
            sellRequest.setTradeType("SELL");
            sellRequest.setQuantity(quantity);
            sellRequest.setPrice(currentPrice);
            sellRequest.setTotalAmount(quantity * currentPrice);
            sellRequest.setDate(LocalDateTime.now().toLocalDate().toString());
            sellRequest.setTime(LocalDateTime.now().toLocalTime().toString());
            
            // Execute the trade
            return executeTrade(sellRequest);
            
        } catch (Exception e) {
            return new TradeResponse("ERROR", "Failed to sell shares: " + e.getMessage());
        }
    }
    
    public List<Trade> getAllTrades() {
        return tradeRepository.findAllByOrderByTimestampDesc();
    }
    
    public Optional<Trade> getTradeById(Long id) {
        return tradeRepository.findById(id);
    }
    
    public List<Trade> getTradesByTicker(String tickerId) {
        return tradeRepository.findByTickerId(tickerId);
    }
    
    public List<Portfolio> getPortfolio() {
        return portfolioRepository.findAll();
    }
    
    public Optional<Portfolio> getPortfolioByTicker(String tickerId) {
        return portfolioRepository.findByTickerId(tickerId);
    }
    
    @Transactional
    public boolean deleteTrade(Long id) {
        if (tradeRepository.existsById(id)) {
            tradeRepository.deleteById(id);
            return true;
        }
        return false;
    }
    
    public void importExternalTrades(MultipartFile file) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream()));
        String line;

        // Skip the header (e.g., Ticker, Company, Quantity, Price)
        reader.readLine();

        while ((line = reader.readLine()) != null) {
            String[] columns = line.split(",");

            String ticker = columns[0];
            String company = columns[1];
            int quantity = Integer.parseInt(columns[2]);
            double price = Double.parseDouble(columns[3]);

            // Logic: Check if user already owns this stock in the Portfolio table
            Portfolio portfolio = portfolioRepository.findByTickerId(ticker)
                    .orElse(new Portfolio(ticker, company, 0, 0.0));

            // Update with new data from the broker file
            int newTotalQuantity = portfolio.getTotalQuantity() + quantity;
            portfolio.setTotalQuantity(newTotalQuantity);
            portfolio.setAveragePrice(price); // Simplified for import

            portfolioRepository.save(portfolio);
        }
    }
}