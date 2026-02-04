package com.stockmarket.controller;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.service.GeminiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    @Autowired private PortfolioRepository portfolioRepository;
    @Autowired private GeminiService geminiService;

    @PostMapping(value = "/ask", consumes = "text/plain")
    public Map<String, Object> handleChat(@RequestBody(required = false) String choice) {
        List<String> options = Arrays.asList("Performance Analysis", "Investment Suggestions");

        if (choice == null || choice.isEmpty() || choice.equals("GREETING")) {
            return Map.of("botMessage", "Hi! I'm your AI Portfolio Advisor. I can analyze your stocks and give suggestions based on your current holdings. What would you like to do?", "options", options);
        }

        // 1. Fetch data from DB
        List<Portfolio> myStocks = portfolioRepository.findAll();
        if (myStocks.isEmpty()) {
            return Map.of("botMessage", "Your portfolio is currently empty. Please add some stocks first so I can analyze them!", "options", options);
        }

        StringBuilder portfolioContext = new StringBuilder();
        for (Portfolio p : myStocks) {
            portfolioContext.append(String.format("- %s (%s): %d shares @ avg price ₹%.2f (Current Value: ₹%.2f)\n",
                    p.getCompanyName(), p.getTickerId(), p.getTotalQuantity(), p.getAveragePrice(), p.getCurrentValue()));
        }

        // 2. Build AI Prompt with "Roleplay" instructions
        String systemInstruction = "You are a highly skilled Stock Market Expert. Use the following user portfolio data:\n" + portfolioContext.toString();
        String userRequest = choice.equals("Performance Analysis")
                ? "Analyze the performance of this portfolio. Calculate total investment and current value. Tell me if I am in profit or loss and provide a brief expert opinion."
                : "Based on these holdings, suggest 3 specific investment moves (Buy/Sell/Hold) and suggest 2 new stocks to watch that complement this portfolio.";

        // 3. Get AI result
        String aiResult = geminiService.getAIResponse(systemInstruction + "\n\nUser Request: " + userRequest);

        return Map.of("botMessage", aiResult, "options", options);
    }
}