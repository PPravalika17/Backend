package com.stockmarket.repository;

import com.stockmarket.entity.Trade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TradeRepository extends JpaRepository<Trade, Long> {
    List<Trade> findByTickerId(String tickerId);
    List<Trade> findByTradeType(String tradeType);
    List<Trade> findByTimestampBetween(LocalDateTime start, LocalDateTime end);
    List<Trade> findAllByOrderByTimestampDesc();
    
    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM Trade t WHERE t.tickerId = ?1 AND t.tradeType = 'BUY'")
    Integer getTotalBoughtQuantity(String tickerId);
    
    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM Trade t WHERE t.tickerId = ?1 AND t.tradeType = 'SELL'")
    Integer getTotalSoldQuantity(String tickerId);
}
