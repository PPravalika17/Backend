package com.stockmarket.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/stocks")
@CrossOrigin(origins = "*")
public class StockController {
    
    private final RestTemplate restTemplate;
    
    @Value("${stock.api.url:https://stock.indianapi.in/trending}")
    private String stockApiUrl;
    
    @Value("${stock.api.nse.url:https://stock.indianapi.in/NSE_most_active}")
    private String nseApiUrl;
    
    @Value("${stock.api.bse.url:https://stock.indianapi.in/BSE_most_active}")
    private String bseApiUrl;
    
    @Value("${stock.api.key}")
    private String apiKey;
    
    public StockController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    @GetMapping("/trending")
    public ResponseEntity<?> getTrendingStocks() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            System.out.println("Fetching trending stocks from: " + stockApiUrl);
            System.out.println("Using API Key: " + (apiKey != null ? apiKey.substring(0, 10) + "..." : "NULL"));
            
            ResponseEntity<Map> response = restTemplate.exchange(
                stockApiUrl, HttpMethod.GET, entity, Map.class
            );
            
            System.out.println("Trending stocks response status: " + response.getStatusCode());
            System.out.println("Trending stocks response body: " + response.getBody());
            
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching trending stocks: " + e.getMessage());
            e.printStackTrace();
            
            // Return mock data if API fails
            return ResponseEntity.ok(getMockTrendingData());
        }
    }
    
    @GetMapping("/nse-active")
    public ResponseEntity<?> getNSEMostActive() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            System.out.println("Fetching NSE active stocks from: " + nseApiUrl);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                nseApiUrl, HttpMethod.GET, entity, Map.class
            );
            
            System.out.println("NSE response: " + response.getBody());
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching NSE data: " + e.getMessage());
            return ResponseEntity.ok(getMockNSEData());
        }
    }
    
    @GetMapping("/bse-active")
    public ResponseEntity<?> getBSEMostActive() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            System.out.println("Fetching BSE active stocks from: " + bseApiUrl);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                bseApiUrl, HttpMethod.GET, entity, Map.class
            );
            
            System.out.println("BSE response: " + response.getBody());
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching BSE data: " + e.getMessage());
            return ResponseEntity.ok(getMockBSEData());
        }
    }
    
    private HttpHeaders createHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Api-Key", apiKey);
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Accept", "application/json");
        return headers;
    }
    
    private Map<String, Object> getMockTrendingData() {
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> trendingStocks = new HashMap<>();
        
        // Mock top gainers
        Object[] topGainers = new Object[] {
            createTrendingStock("RELIANCE.NS", "Reliance Industries Ltd", 2850.75, 45.50, 1.62, 1850000, 2820.50, 2865.90, 2810.00, 2805.25, "NSE"),
            createTrendingStock("TCS.NS", "Tata Consultancy Services", 3685.40, 52.30, 1.44, 950000, 3650.00, 3695.50, 3645.00, 3633.10, "NSE"),
            createTrendingStock("INFY.NS", "Infosys Limited", 1520.90, 28.75, 1.93, 1250000, 1505.00, 1528.50, 1500.00, 1492.15, "NSE"),
            createTrendingStock("HDFCBANK.NS", "HDFC Bank", 1685.50, 35.20, 2.13, 2100000, 1665.00, 1692.00, 1660.00, 1650.30, "NSE"),
            createTrendingStock("ICICIBANK.NS", "ICICI Bank", 1045.75, 22.40, 2.19, 1850000, 1030.00, 1050.50, 1028.00, 1023.35, "NSE")
        };
        
        // Mock top losers
        Object[] topLosers = new Object[] {
            createTrendingStock("YESBANK.BO", "Yes Bank", 18.45, -0.85, -4.40, 5200000, 19.50, 19.60, 18.30, 19.30, "BSE"),
            createTrendingStock("SUZLON.BO", "Suzlon Energy", 52.30, -2.15, -3.95, 3500000, 54.80, 55.00, 52.00, 54.45, "BSE"),
            createTrendingStock("VODAFONE.NS", "Vodafone Idea", 11.25, -0.55, -4.66, 8500000, 11.90, 12.00, 11.10, 11.80, "NSE")
        };
        
        // Mock most active
        Object[] mostActive = new Object[] {
            createTrendingStock("TATASTEEL.NS", "Tata Steel", 145.80, 2.30, 1.60, 8500000, 144.50, 147.20, 143.80, 143.50, "NSE"),
            createTrendingStock("ONGC.NS", "Oil and Natural Gas Corporation", 285.40, -1.25, -0.44, 4500000, 287.00, 288.50, 284.00, 286.65, "NSE"),
            createTrendingStock("ITC.NS", "ITC Limited", 465.20, 3.85, 0.83, 3200000, 462.50, 467.00, 461.00, 461.35, "NSE"),
            createTrendingStock("BHARTIARTL.NS", "Bharti Airtel", 1250.50, -5.30, -0.42, 2800000, 1258.00, 1262.00, 1248.00, 1255.80, "NSE"),
            createTrendingStock("BAJFINANCE.NS", "Bajaj Finance", 7125.40, 85.60, 1.22, 950000, 7080.00, 7145.00, 7065.00, 7039.80, "NSE")
        };
        
        trendingStocks.put("top_gainers", topGainers);
        trendingStocks.put("top_losers", topLosers);
        trendingStocks.put("most_active", mostActive);
        response.put("trending_stocks", trendingStocks);
        
        System.out.println("Returning mock trending data");
        return response;
    }
    
    private Map<String, Object> createTrendingStock(String tickerId, String companyName, 
                                                   double price, double change, double changePercent,
                                                   int volume, double open, double high, 
                                                   double low, double prevClose, String exchange) {
        Map<String, Object> stock = new HashMap<>();
        stock.put("ticker_id", tickerId);
        stock.put("company_name", companyName);
        stock.put("price", price);
        stock.put("change", change);
        stock.put("change_percent", changePercent);
        stock.put("volume", volume);
        stock.put("open", open);
        stock.put("high", high);
        stock.put("low", low);
        stock.put("prev_close", prevClose);
        stock.put("exchange", exchange);
        return stock;
    }
    
    private Map<String, Object> getMockNSEData() {
        Map<String, Object> response = new HashMap<>();
        Object[] mostActive = new Object[] {
            createStockPrice("ETEA.NS", 451.95),
            createStockPrice("ONGC.NS", 285.40),
            createStockPrice("BAJE.NS", 289.75),
            createStockPrice("HZNC.NS", 512.30),
            createStockPrice("HDBK.NS", 1725.80),
            createStockPrice("TISC.NS", 158.65),
            createStockPrice("ITC.NS", 465.20),
            createStockPrice("VDAN.NS", 451.90),
            createStockPrice("CNBK.NS", 105.45),
            createStockPrice("INID.NS", 125.80)
        };
        response.put("most_active", mostActive);
        return response;
    }
    
    private Map<String, Object> getMockBSEData() {
        Map<String, Object> response = new HashMap<>();
        Object[] mostActive = new Object[] {
            createStockPrice("SUZL.BO", 65.25),
            createStockPrice("YESB.BO", 22.40),
            createStockPrice("ONGC.BO", 285.40),
            createStockPrice("BAJE.BO", 289.75),
            createStockPrice("ETEA.BO", 451.95),
            createStockPrice("KTKM.BO", 1845.60),
            createStockPrice("TISC.BO", 158.65),
            createStockPrice("CNBK.BO", 105.45),
            createStockPrice("BJFS.BO", 1685.30),
            createStockPrice("VDAN.BO", 451.90)
        };
        response.put("most_active", mostActive);
        return response;
    }
    
    private Map<String, Object> createStockPrice(String tickerId, double price) {
        Map<String, Object> stock = new HashMap<>();
        stock.put("ticker_id", tickerId);
        stock.put("price", price);
        return stock;
    }
}