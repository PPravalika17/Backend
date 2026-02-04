package com.stockmarket.controller;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.repository.TradeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {
    
    @Autowired
    private TradeRepository tradeRepository;
    
    @Autowired
    private PortfolioRepository portfolioRepository;
    
    @Autowired
    private RestTemplate restTemplate;
    
    @Value("${stock.api.nse.url:https://stock.indianapi.in/NSE_most_active}")
    private String nseApiUrl;
    
    @Value("${stock.api.bse.url:https://stock.indianapi.in/BSE_most_active}")
    private String bseApiUrl;
    
    @Value("${stock.api.key:sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v}")
    private String apiKey;
    
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        try {
            Map<String, Object> stats = new HashMap<>();
            
            // Get all portfolios and trades
            List<Portfolio> portfolios = portfolioRepository.findAll();
            List<Trade> allTrades = tradeRepository.findAll();
            
            // Fetch live market data
            Map<String, Double> marketPrices = fetchMarketPrices();
            
            // Total unique stocks
            stats.put("totalStocks", portfolios.size());
            
            // Calculate total investment and current value
            double totalInvestment = 0;
            double totalCurrentValue = 0;
            
            for (Portfolio p : portfolios) {
                totalInvestment += p.getAveragePrice() * p.getTotalQuantity();
                
                // Get current price from market data
                Double currentPrice = marketPrices.get(p.getTickerId());
                if (currentPrice != null) {
                    totalCurrentValue += currentPrice * p.getTotalQuantity();
                } else {
                    // Fallback to average price if market data not available
                    totalCurrentValue += p.getAveragePrice() * p.getTotalQuantity();
                }
            }
            
            stats.put("totalInvestment", totalInvestment);
            stats.put("totalCurrentValue", totalCurrentValue);
            
            // Calculate profit/loss
            double profitLoss = totalCurrentValue - totalInvestment;
            double profitLossPercentage = totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0;
            
            stats.put("profitLoss", profitLoss);
            stats.put("profitLossPercentage", profitLossPercentage);
            stats.put("isProfit", profitLoss >= 0);
            
            // Buy vs Sell statistics
            long buyCount = allTrades.stream().filter(t -> "BUY".equals(t.getTradeType())).count();
            long sellCount = allTrades.stream().filter(t -> "SELL".equals(t.getTradeType())).count();
            
            stats.put("buyCount", buyCount);
            stats.put("sellCount", sellCount);
            
            // Calculate buy/sell amounts
            double totalBuyAmount = allTrades.stream()
                .filter(t -> "BUY".equals(t.getTradeType()))
                .mapToDouble(Trade::getTotalAmount)
                .sum();
            
            double totalSellAmount = allTrades.stream()
                .filter(t -> "SELL".equals(t.getTradeType()))
                .mapToDouble(Trade::getTotalAmount)
                .sum();
            
            stats.put("totalBuyAmount", totalBuyAmount);
            stats.put("totalSellAmount", totalSellAmount);
            
            // Market sentiment (Bullish if profit > 5%, Bearish if loss > 5%, Neutral otherwise)
            String sentiment;
            if (profitLossPercentage > 5) {
                sentiment = "Bullish";
            } else if (profitLossPercentage < -5) {
                sentiment = "Bearish";
            } else {
                sentiment = "Neutral";
            }
            stats.put("marketSentiment", sentiment);
            
            // Stock-wise performance
            List<Map<String, Object>> stockPerformance = new ArrayList<>();
            for (Portfolio p : portfolios) {
                Map<String, Object> stockData = new HashMap<>();
                stockData.put("tickerId", p.getTickerId());
                stockData.put("companyName", p.getCompanyName());
                stockData.put("quantity", p.getTotalQuantity());
                stockData.put("avgPrice", p.getAveragePrice());
                
                Double currentPrice = marketPrices.get(p.getTickerId());
                if (currentPrice != null) {
                    double invested = p.getAveragePrice() * p.getTotalQuantity();
                    double current = currentPrice * p.getTotalQuantity();
                    double pl = current - invested;
                    double plPercent = (pl / invested) * 100;
                    
                    stockData.put("currentPrice", currentPrice);
                    stockData.put("profitLoss", pl);
                    stockData.put("profitLossPercent", plPercent);
                    stockData.put("isProfit", pl >= 0);
                }
                
                stockPerformance.add(stockData);
            }
            stats.put("stockPerformance", stockPerformance);
            
            // Monthly profit/loss trend (last 12 months)
            Map<String, Double> monthlyTrend = calculateMonthlyTrend(allTrades, marketPrices);
            stats.put("monthlyTrend", monthlyTrend);
            
            // Top gainers and losers
            List<Map<String, Object>> sortedByPL = new ArrayList<>(stockPerformance);
            sortedByPL.sort((a, b) -> {
                Double plA = (Double) a.getOrDefault("profitLoss", 0.0);
                Double plB = (Double) b.getOrDefault("profitLoss", 0.0);
                return Double.compare(plB, plA);
            });
            
            List<Map<String, Object>> topGainers = sortedByPL.stream()
                .filter(s -> (Double) s.getOrDefault("profitLoss", 0.0) > 0)
                .limit(3)
                .collect(Collectors.toList());
            
            List<Map<String, Object>> topLosers = sortedByPL.stream()
                .filter(s -> (Double) s.getOrDefault("profitLoss", 0.0) < 0)
                .limit(3)
                .collect(Collectors.toList());
            
            stats.put("topGainers", topGainers);
            stats.put("topLosers", topLosers);
            
            return ResponseEntity.ok(stats);
            
        } catch (Exception e) {
            System.err.println("Error calculating dashboard stats: " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to calculate dashboard statistics");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
    
    private Map<String, Double> fetchMarketPrices() {
        Map<String, Double> prices = new HashMap<>();
        
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Api-Key", apiKey);
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            // Fetch NSE prices
            try {
                ResponseEntity<Map> nseResponse = restTemplate.exchange(
                    nseApiUrl, HttpMethod.GET, entity, Map.class
                );
                if (nseResponse.getBody() != null && nseResponse.getBody().get("most_active") != null) {
                    List<Map<String, Object>> stocks = (List<Map<String, Object>>) nseResponse.getBody().get("most_active");
                    for (Map<String, Object> stock : stocks) {
                        String tickerId = (String) stock.get("ticker_id");
                        Object priceObj = stock.get("price");
                        if (tickerId != null && priceObj != null) {
                            Double price = priceObj instanceof Number ? 
                                ((Number) priceObj).doubleValue() : 
                                Double.parseDouble(priceObj.toString());
                            prices.put(tickerId, price);
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Error fetching NSE prices: " + e.getMessage());
            }
            
            // Fetch BSE prices
            try {
                ResponseEntity<Map> bseResponse = restTemplate.exchange(
                    bseApiUrl, HttpMethod.GET, entity, Map.class
                );
                if (bseResponse.getBody() != null && bseResponse.getBody().get("most_active") != null) {
                    List<Map<String, Object>> stocks = (List<Map<String, Object>>) bseResponse.getBody().get("most_active");
                    for (Map<String, Object> stock : stocks) {
                        String tickerId = (String) stock.get("ticker_id");
                        Object priceObj = stock.get("price");
                        if (tickerId != null && priceObj != null) {
                            Double price = priceObj instanceof Number ? 
                                ((Number) priceObj).doubleValue() : 
                                Double.parseDouble(priceObj.toString());
                            prices.put(tickerId, price);
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Error fetching BSE prices: " + e.getMessage());
            }
            
        } catch (Exception e) {
            System.err.println("Error in fetchMarketPrices: " + e.getMessage());
        }
        
        return prices;
    }
    
    private Map<String, Double> calculateMonthlyTrend(List<Trade> trades, Map<String, Double> marketPrices) {
        Map<String, Double> monthlyTrend = new LinkedHashMap<>();
        
        LocalDateTime now = LocalDateTime.now();
        
        for (int i = 11; i >= 0; i--) {
            LocalDateTime monthStart = now.minusMonths(i).withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime monthEnd = monthStart.plusMonths(1).minusSeconds(1);
            
            String monthKey = monthStart.getMonth().toString().substring(0, 3) + " " + monthStart.getYear();
            
            // Calculate profit/loss for this month
            List<Trade> monthTrades = trades.stream()
                .filter(t -> t.getTimestamp() != null && 
                           t.getTimestamp().isAfter(monthStart) && 
                           t.getTimestamp().isBefore(monthEnd))
                .collect(Collectors.toList());
            
            double monthPL = 0;
            for (Trade trade : monthTrades) {
                if ("SELL".equals(trade.getTradeType())) {
                    // Simplified: assume profit on sell
                    monthPL += trade.getTotalAmount() * 0.05; // 5% assumed profit
                }
            }
            
            monthlyTrend.put(monthKey, monthPL);
        }
        
        return monthlyTrend;
    }
}
