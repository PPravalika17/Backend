package com.stockmarket.service;

import com.stockmarket.entity.Portfolio;
import com.stockmarket.repository.PortfolioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PortfolioServiceTest {
    @Mock private PortfolioRepository portfolioRepository;
    @InjectMocks private PortfolioService portfolioService;
    private Portfolio portfolio;

    @BeforeEach
    void setUp() {
        portfolio = new Portfolio();
        portfolio.setTickerId("RELIANCE.NS");
        portfolio.setTotalQuantity(10);
        portfolio.setAveragePrice(2850.50);
        portfolio.setCreatedAt(LocalDateTime.now());
    }

    @Test
    void testGetAllPortfolio() {
        List<Portfolio> portfolios = new ArrayList<>();
        portfolios.add(portfolio);
        when(portfolioRepository.findAll()).thenReturn(portfolios);
        List<Portfolio> result = portfolioService.getAllPortfolio();
        assertEquals(1, result.size());
        assertEquals("RELIANCE.NS", result.get(0).getTickerId());
    }

    @Test
    void testImportFromCSV_ValidFile() {
        String csv = "EXCHANGE,SYMBOL,NAME,QUANTITY,PRICE,TIMESTAMP\n" +
                    "NSE,RELIANCE.NS,\"Reliance\",10,2850.50,2026-02-04T10:30:00\n";
        MockMultipartFile file = new MockMultipartFile("file", "test.csv", "text/csv", csv.getBytes());
        when(portfolioRepository.findByTickerId(anyString())).thenReturn(Optional.empty());
        when(portfolioRepository.save(any(Portfolio.class))).thenReturn(portfolio);
        Map<String, Object> result = portfolioService.importFromCSV(file);
        assertTrue((Boolean) result.get("success"));
    }

    @Test
    void testImportFromCSV_InvalidHeader() {
        String csv = "WRONG,HEADER\nNSE,TEST\n";
        MockMultipartFile file = new MockMultipartFile("file", "test.csv", "text/csv", csv.getBytes());
        Map<String, Object> result = portfolioService.importFromCSV(file);
        assertFalse((Boolean) result.get("success"));
    }
}
