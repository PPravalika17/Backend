package com.stockmarket.model;

import java.util.List;

public class ChatResponse {
    private String botMessage;
    private List<String> options;

    public ChatResponse(String botMessage, List<String> options) {
        this.botMessage = botMessage;
        this.options = options;
    }

    // Getters and Setters
    public String getBotMessage() { return botMessage; }
    public void setBotMessage(String botMessage) { this.botMessage = botMessage; }
    public List<String> getOptions() { return options; }
    public void setOptions(List<String> options) { this.options = options; }
}