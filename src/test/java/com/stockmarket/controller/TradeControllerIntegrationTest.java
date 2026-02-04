package com.stockmarket.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.stockmarket.dto.TradeRequest;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class TradeControllerIntegrationTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private TradeRepository tradeRepository;
    @Autowired private PortfolioRepository portfolioRepository;

    @BeforeEach
    void setUp() {
        tradeRepository.deleteAll();
        portfolioRepository.deleteAll();
    }

    @Test
    void testExecuteTrade_BuyOrder() throws Exception {
        TradeRequest request = new TradeRequest();
        request.setTickerId("RELIANCE.NS");
        request.setCompanyName("Reliance");
        request.setTradeType("BUY");
        request.setQuantity(10);
        request.setPrice(2850.50);
        request.setTotalAmount(28505.00);
        mockMvc.perform(post("/api/trades")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("SUCCESS"));
    }

    @Test
    void testGetAllTrades() throws Exception {
        mockMvc.perform(get("/api/trades"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void testGetPortfolio() throws Exception {
        Portfolio p = new Portfolio();
        p.setTickerId("RELIANCE.NS");
        p.setTotalQuantity(10);
        p.setAveragePrice(2850.50);
        p.setCreatedAt(LocalDateTime.now());
        p.setLastUpdated(LocalDateTime.now());
        portfolioRepository.save(p);
        mockMvc.perform(get("/api/trades/portfolio"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }
}
