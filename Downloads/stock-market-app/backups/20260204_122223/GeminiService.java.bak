package com.stockmarket.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@Service
public class GeminiService {
    private final String API_KEY = "AIzaSyBtODJB9iZ_dvx4sp7xhkhjyCEDLXwDTUg";
    //private final String URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + API_KEY;
    // Change v1beta to v1 and ensure the model name is exactly gemini-1.5-flash
    // Use v1beta (most flexible) and ensure the model name is spelled exactly like this
    private final String URL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=" + API_KEY;

    public String getAIResponse(String prompt) {
        RestTemplate restTemplate = new RestTemplate();

        // The structure MUST be contents -> parts -> text
        Map<String, Object> textPart = Map.of("text", prompt);
        Map<String, Object> contentsPart = Map.of("parts", List.of(textPart));
        Map<String, Object> requestBody = Map.of("contents", List.of(contentsPart));

        try {
            // Sending the request to Google
            Map<String, Object> response = restTemplate.postForObject(URL, requestBody, Map.class);

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