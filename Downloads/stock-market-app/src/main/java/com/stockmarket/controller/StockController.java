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
    
    @Value("${stock.api.key:sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v}")
    private String apiKey;
    
    public StockController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    @GetMapping("/trending")
    public ResponseEntity<?> getTrendingStocks() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                stockApiUrl, HttpMethod.GET, entity, Map.class
            );
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching trending stocks: " + e.getMessage());
            return ResponseEntity.ok(getMockStockData());
        }
    }
    
    @GetMapping("/nse-active")
    public ResponseEntity<?> getNSEMostActive() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                nseApiUrl, HttpMethod.GET, entity, Map.class
            );
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
            
            ResponseEntity<Map> response = restTemplate.exchange(
                bseApiUrl, HttpMethod.GET, entity, Map.class
            );
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
        return headers;
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
    
    private Map<String, Object> getMockStockData() {
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> trendingStocks = new HashMap<>();
        
        Object[] topGainers = new Object[] {
            createStock("RELIANCE", "Reliance Industries Ltd", 2500.50, 1500000),
            createStock("TCS", "Tata Consultancy Services", 3500.75, 800000),
            createStock("INFY", "Infosys Limited", 1450.25, 1200000)
        };
        
        trendingStocks.put("top_gainers", topGainers);
        trendingStocks.put("top_losers", new Object[]{});
        response.put("trending_stocks", trendingStocks);
        return response;
    }
    
    private Map<String, Object> createStock(String tickerId, String companyName, double price, int volume) {
        Map<String, Object> stock = new HashMap<>();
        stock.put("ticker_id", tickerId);
        stock.put("company_name", companyName);
        stock.put("price", price);
        stock.put("volume", volume);
        return stock;
    }
}
