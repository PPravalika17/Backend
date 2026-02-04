package com.stockmarket.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@Service
public class GeminiService {
    
    @Value("${gemini.api.key}")
    private String API_KEY;
    
    @Value("${gemini.api.url}")
    private String GEMINI_URL;

    public String getAIResponse(String prompt) {
        RestTemplate restTemplate = new RestTemplate();
        
        // Build the full URL with API key
        String url = GEMINI_URL + "?key=" + API_KEY;

        // The structure MUST be contents -> parts -> text
        Map<String, Object> textPart = Map.of("text", prompt);
        Map<String, Object> contentsPart = Map.of("parts", List.of(textPart));
        Map<String, Object> requestBody = Map.of("contents", List.of(contentsPart));

        try {
            // Sending the request to Google
            Map<String, Object> response = restTemplate.postForObject(url, requestBody, Map.class);

            // Digging through the JSON response to find the text
            List candidates = (List) response.get("candidates");
            Map firstCandidate = (Map) candidates.get(0);
            Map content = (Map) firstCandidate.get("content");
            List parts = (List) content.get("parts");
            Map firstPart = (Map) parts.get(0);

            return (String) firstPart.get("text");
        } catch (Exception e) {
            e.printStackTrace(); // This will print the full technical error in your IntelliJ console
            return "AI Error: " + e.getMessage();
        }
    }
}
