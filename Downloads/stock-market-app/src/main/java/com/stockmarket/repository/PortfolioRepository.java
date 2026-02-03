package com.stockmarket.repository;

import com.stockmarket.entity.Portfolio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PortfolioRepository extends JpaRepository<Portfolio, Long> {
    Optional<Portfolio> findByTickerId(String tickerId);
    boolean existsByTickerId(String tickerId);
    void deleteByTickerId(String tickerId);
}
