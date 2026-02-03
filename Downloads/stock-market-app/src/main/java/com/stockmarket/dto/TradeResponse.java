package com.stockmarket.dto;

import java.time.LocalDateTime;

public class TradeResponse {
    private Long id;
    private String tickerId;
    private String companyName;
    private String tradeType;
    private Integer quantity;
    private Double price;
    private Double totalAmount;
    private String date;
    private String time;
    private LocalDateTime timestamp;
    private String status;
    private String message;
    
    public TradeResponse() {}
    
    public TradeResponse(String status, String message) {
        this.status = status;
        this.message = message;
    }
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getTickerId() { return tickerId; }
    public void setTickerId(String tickerId) { this.tickerId = tickerId; }
    
    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }
    
    public String getTradeType() { return tradeType; }
    public void setTradeType(String tradeType) { this.tradeType = tradeType; }
    
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    
    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }
    
    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }
    
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    
    public String getTime() { return time; }
    public void setTime(String time) { this.time = time; }
    
    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
