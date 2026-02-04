package com.stockmarket.service;

import com.stockmarket.dto.TradeRequest;
import com.stockmarket.dto.TradeResponse;
import com.stockmarket.entity.Portfolio;
import com.stockmarket.entity.Trade;
import com.stockmarket.repository.PortfolioRepository;
import com.stockmarket.repository.TradeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TradeServiceTest {
    @Mock private TradeRepository tradeRepository;
    @Mock private PortfolioRepository portfolioRepository;
    @InjectMocks private TradeService tradeService;
    private TradeRequest buyRequest;
    private Portfolio portfolio;
    private Trade trade;

    @BeforeEach
    void setUp() {
        buyRequest = new TradeRequest();
        buyRequest.setTickerId("RELIANCE.NS");
        buyRequest.setCompanyName("Reliance Industries");
        buyRequest.setTradeType("BUY");
        buyRequest.setQuantity(10);
        buyRequest.setPrice(2850.50);
        buyRequest.setTotalAmount(28505.00);
        portfolio = new Portfolio();
        portfolio.setId(1L);
        portfolio.setTickerId("RELIANCE.NS");
        portfolio.setTotalQuantity(10);
        portfolio.setAveragePrice(2850.50);
        trade = new Trade();
        trade.setId(1L);
        trade.setTickerId("RELIANCE.NS");
        trade.setTradeType("BUY");
        trade.setQuantity(10);
        trade.setPrice(2850.50);
    }

    @Test
    void testExecuteTrade_BuyNewStock_Success() {
        when(portfolioRepository.findByTickerId(buyRequest.getTickerId())).thenReturn(Optional.empty());
        when(tradeRepository.save(any(Trade.class))).thenReturn(trade);
        when(portfolioRepository.save(any(Portfolio.class))).thenReturn(portfolio);
        TradeResponse response = tradeService.executeTrade(buyRequest);
        assertNotNull(response);
        assertEquals("SUCCESS", response.getStatus());
        verify(tradeRepository, times(1)).save(any(Trade.class));
    }

    @Test
    void testExecuteTrade_InvalidTickerId() {
        buyRequest.setTickerId(null);
        TradeResponse response = tradeService.executeTrade(buyRequest);
        assertEquals("ERROR", response.getStatus());
        assertEquals("Ticker ID is required", response.getMessage());
    }

    @Test
    void testSellFromPortfolio_Success() {
        when(portfolioRepository.findByTickerId("RELIANCE.NS")).thenReturn(Optional.of(portfolio));
        when(tradeRepository.save(any(Trade.class))).thenReturn(trade);
        TradeResponse response = tradeService.sellFromPortfolio("RELIANCE.NS", 5, 2900.00);
        assertEquals("SUCCESS", response.getStatus());
    }
}
