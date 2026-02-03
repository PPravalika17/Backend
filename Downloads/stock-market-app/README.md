# Stock Market Trading Platform

A full-stack stock market trading application built with Spring Boot and vanilla JavaScript.

## Features

- **Buy/Sell Stocks**: Execute trades with validation
- **Portfolio Management**: Track all your holdings
- **Trade History**: View all past transactions
- **Real-time Updates**: Auto-refresh stock data
- **Responsive Design**: Works on all devices

## Tech Stack

- **Backend**: Spring Boot 3.2.0, JPA/Hibernate
- **Database**: H2 (In-memory)
- **Frontend**: HTML5, CSS3, Vanilla JavaScript

## Quick Start

### Prerequisites
- Java 17+
- Maven 3.6+

### Run the Application

```bash
# Build
mvn clean install

# Run
mvn spring-boot:run
```

### Access

- **Frontend**: http://localhost:8080/index.html
- **H2 Console**: http://localhost:8080/h2-console
- **API**: http://localhost:8080/api

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/trades` | Execute trade |
| GET | `/api/trades` | Get all trades |
| GET | `/api/trades/{id}` | Get trade by ID |
| GET | `/api/trades/portfolio` | Get portfolio |

## Testing

```bash
# Test buy operation
curl -X POST http://localhost:8080/api/trades \
  -H "Content-Type: application/json" \
  -d '{
    "tickerId": "AAPL",
    "companyName": "Apple Inc",
    "tradeType": "BUY",
    "quantity": 10,
    "price": 150.00,
    "totalAmount": 1500.00
  }'
```

## Database

H2 in-memory database is used by default. To switch to MySQL/PostgreSQL, update `application.properties`.

## License

MIT License
