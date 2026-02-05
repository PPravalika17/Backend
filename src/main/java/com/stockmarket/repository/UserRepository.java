package com.stockmarket.repository;

import com.stockmarket.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // This allows Spring Security to find a user by their username during login
    Optional<User> findByUsername(String username);
}