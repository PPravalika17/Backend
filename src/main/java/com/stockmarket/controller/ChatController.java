package com.stockmarket.controller;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.repository.TradeRepository;
import com.stockmarket.service.GeminiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    @Autowired private PortfolioRepository portfolioRepository;
    @Autowired private TradeRepository tradeRepository;
    @Autowired private GeminiService geminiService;

    @PostMapping(value = "/ask", consumes = "text/plain")
    public Map<String, Object> handleChat(@RequestBody(required = false) String choice) {
        List<String> options = Arrays.asList("Analyze your Portfolio", "Guide with Suggestions");

        // Initial greeting
        if (choice == null || choice.isEmpty() || choice.equals("GREETING")) {
            return Map.of(
                "botMessage", "👋 Hi! I'm your AI Portfolio Advisor powered by Gemini. I can help you with:\n\n" +
                              "📊 **Analyze your Portfolio** - Get insights on your holdings, profit/loss analysis, and performance evaluation\n\n" +
                              "💡 **Guide with Suggestions** - Receive personalized trading recommendations based on your trade history\n\n" +
                              "What would you like to do today?",
                "options", options
            );
        }

        try {
            if (choice.equals("Analyze your Portfolio")) {
                return analyzePortfolio();
            } else if (choice.equals("Guide with Suggestions")) {
                return provideSuggestions();
            } else {
                return Map.of(
                    "botMessage", "I didn't understand that option. Please choose from the menu below:",
                    "options", options
                );
            }
        } catch (Exception e) {
            System.err.println("Error in chat handler: " + e.getMessage());
            e.printStackTrace();
            return Map.of(
                "botMessage", "⚠️ Sorry, I encountered an error while processing your request. Please try again.",
                "options", options
            );
        }
    }

    /**
     * Analyze Portfolio - Fetches portfolio data and asks Gemini for analysis
     */
    private Map<String, Object> analyzePortfolio() {
        List<Portfolio> portfolioList = portfolioRepository.findAll();

        if (portfolioList.isEmpty()) {
            return Map.of(
                "botMessage", "📭 Your portfolio is currently empty. Please add some stocks first so I can analyze them!\n\n" +
                              "Click the + button on the Portfolio tab to get started.",
                "options", Arrays.asList("Analyze your Portfolio", "Guide with Suggestions")
            );
        }

        // Build portfolio context for Gemini
        StringBuilder portfolioContext = new StringBuilder();
        portfolioContext.append("USER PORTFOLIO DATA:\n\n");
        
        double totalInvestment = 0;
        double totalCurrentValue = 0;
        
        for (Portfolio p : portfolioList) {
            double invested = p.getAveragePrice() * p.getTotalQuantity();
            double currentValue = p.getCurrentValue();
            
            totalInvestment += invested;
            totalCurrentValue += currentValue;
            
            portfolioContext.append(String.format(
                "Stock: %s (%s)\n" +
                "- Quantity: %d shares\n" +
                "- Average Purchase Price: ₹%.2f\n" +
                "- Current Value: ₹%.2f\n" +
                "- Invested Amount: ₹%.2f\n\n",
                p.getCompanyName(), p.getTickerId(), p.getTotalQuantity(), 
                p.getAveragePrice(), currentValue, invested
            ));
        }
        
        double totalProfitLoss = totalCurrentValue - totalInvestment;
        double profitLossPercentage = (totalProfitLoss / totalInvestment) * 100;
        
        portfolioContext.append(String.format(
            "PORTFOLIO SUMMARY:\n" +
            "- Total Investment: ₹%.2f\n" +
            "- Total Current Value: ₹%.2f\n" +
            "- Overall Profit/Loss: ₹%.2f (%.2f%%)\n" +
            "- Status: %s\n",
            totalInvestment, totalCurrentValue, totalProfitLoss, 
            profitLossPercentage, totalProfitLoss >= 0 ? "PROFIT" : "LOSS"
        ));

        // Gemini prompt for portfolio analysis
        String prompt = portfolioContext.toString() + "\n\n" +
            "As an expert stock market analyst, please analyze this portfolio and provide:\n" +
            "1. Overall portfolio health assessment\n" +
            "2. Individual stock performance analysis\n" +
            "3. Risk evaluation (are holdings diversified?)\n" +
            "4. Specific recommendations for each stock (Hold/Sell/Buy more)\n" +
            "5. Any red flags or concerns\n\n" +
            "Please format your response in a clear, professional manner with emojis for better readability.";

        String aiResponse = geminiService.getAIResponse(prompt);

        return Map.of(
            "botMessage", "📊 **PORTFOLIO ANALYSIS**\n\n" + aiResponse,
            "options", Arrays.asList("Analyze your Portfolio", "Guide with Suggestions")
        );
    }

    /**
     * Guide with Suggestions - Fetches trade history and asks Gemini for trading guidance
     */
    private Map<String, Object> provideSuggestions() {
        List<Trade> tradeList = tradeRepository.findAll();

        if (tradeList.isEmpty()) {
            return Map.of(
                "botMessage", "📭 You haven't made any trades yet. Start trading to get personalized suggestions!\n\n" +
                              "I'll analyze your trading patterns and provide insights once you have some trade history.",
                "options", Arrays.asList("Analyze your Portfolio", "Guide with Suggestions")
            );
        }

        // Build trade history context for Gemini
        StringBuilder tradeContext = new StringBuilder();
        tradeContext.append("USER TRADE HISTORY:\n\n");
        
        int buyCount = 0;
        int sellCount = 0;
        double totalBuyAmount = 0;
        double totalSellAmount = 0;
        Map<String, List<Trade>> tradesByStock = new HashMap<>();
        
        for (Trade trade : tradeList) {
            if ("BUY".equals(trade.getTradeType())) {
                buyCount++;
                totalBuyAmount += trade.getTotalAmount();
            } else {
                sellCount++;
                totalSellAmount += trade.getTotalAmount();
            }
            
            tradesByStock.computeIfAbsent(trade.getTickerId(), k -> new ArrayList<>()).add(trade);
        }
        
        tradeContext.append(String.format(
            "TRADING SUMMARY:\n" +
            "- Total Trades: %d\n" +
            "- Buy Orders: %d (Total: ₹%.2f)\n" +
            "- Sell Orders: %d (Total: ₹%.2f)\n" +
            "- Unique Stocks Traded: %d\n\n",
            tradeList.size(), buyCount, totalBuyAmount, sellCount, totalSellAmount, tradesByStock.size()
        ));
        
        tradeContext.append("STOCK-WISE TRADE BREAKDOWN:\n");
        for (Map.Entry<String, List<Trade>> entry : tradesByStock.entrySet()) {
            String symbol = entry.getKey();
            List<Trade> trades = entry.getValue();
            
            tradeContext.append(String.format("\n%s (%s):\n", 
                trades.get(0).getCompanyName(), symbol));
            
            for (Trade trade : trades) {
                tradeContext.append(String.format(
                    "  - %s: %d shares @ ₹%.2f (Total: ₹%.2f) on %s\n",
                    trade.getTradeType(), trade.getQuantity(), trade.getPrice(), 
                    trade.getTotalAmount(), trade.getTimestamp()
                ));
            }
        }

        // Gemini prompt for trading suggestions
        String prompt = tradeContext.toString() + "\n\n" +
            "As an experienced stock market advisor, please analyze this trading history and provide:\n" +
            "1. Trading pattern analysis (Are they trading frequently or holding long-term?)\n" +
            "2. Behavioral insights (Any impulsive buying/selling patterns?)\n" +
            "3. Risk management evaluation\n" +
            "4. Specific actionable suggestions for improvement\n" +
            "5. Recommended trading strategies based on their history\n" +
            "6. Stocks they should consider buying/selling based on current holdings\n\n" +
            "Please provide practical, actionable advice formatted clearly with emojis.";

        String aiResponse = geminiService.getAIResponse(prompt);

        return Map.of(
            "botMessage", "💡 **TRADING GUIDANCE & SUGGESTIONS**\n\n" + aiResponse,
            "options", Arrays.asList("Analyze your Portfolio", "Guide with Suggestions")
        );
    }
}
