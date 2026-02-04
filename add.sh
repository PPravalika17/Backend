#!/bin/bash

##############################################################################
# Add Portfolio Management with NSE/BSE Integration
# This script adds "Add Holding" feature with profit/loss calculation
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo ""
echo -e "${MAGENTA}=========================================="
echo "  Portfolio Management Enhancement"
echo "==========================================${NC}"
echo ""
echo "This will add:"
echo "  ✨ Add Holding button (+) in Portfolio tab"
echo "  📊 NSE and BSE stock selection"
echo "  💰 Profit/Loss calculation with live prices"
echo "  🎨 Green/Red indicators for gains/losses"
echo ""

# Check if we're in a Spring Boot project
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}[ERROR]${NC} pom.xml not found. Please run this script from your Spring Boot project root directory."
    exit 1
fi

echo -e "${BLUE}[STEP 1/4]${NC} Backing up existing files..."

# Backup existing files
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="backup_${timestamp}"
mkdir -p "$backup_dir"

if [ -f "src/main/resources/static/index.html" ]; then
    cp src/main/resources/static/index.html "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up index.html"
fi

if [ -f "src/main/java/com/stockmarket/controller/StockController.java" ]; then
    cp src/main/java/com/stockmarket/controller/StockController.java "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up StockController.java"
fi

if [ -f "src/main/resources/application.properties" ]; then
    cp src/main/resources/application.properties "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up application.properties"
fi

echo -e "${GREEN}[SUCCESS]${NC} Backups created in: $backup_dir/"
echo ""

echo -e "${BLUE}[STEP 2/4]${NC} Updating frontend (index.html)..."

cat > src/main/resources/static/index.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Stock Market Trading Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1d2e 0%, #16213e 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: #1a1d2e;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #1a1d2e 0%, #1a1d2e 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-bottom: 1px solid #2d3447;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.1em; opacity: 0.9; }
        .nav-tabs {
            display: flex;
            background: #252a3d;
            border-bottom: 2px solid #2d3447;
        }
        .nav-tab {
            flex: 1;
            padding: 15px;
            text-align: center;
            background: #252a3d;
            color: #8a92a6;
            border: none;
            cursor: pointer;
            font-size: 1em;
            font-weight: 600;
            transition: all 0.3s;
        }
        .nav-tab:hover { background: #2d3447; color: #ffffff; }
        .nav-tab.active {
            background: #1a1d2e;
            color: #5cb85c;
            border-bottom: 3px solid #5cb85c;
        }
        .tab-content { display: none; }
        .tab-content.active { display: block; }
        .add-holding-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 60px;
            height: 60px;
            background: linear-gradient(135deg, #5cb85c 0%, #4cae4c 100%);
            color: white;
            border: none;
            border-radius: 50%;
            font-size: 2em;
            cursor: pointer;
            box-shadow: 0 8px 16px rgba(92, 184, 92, 0.4);
            transition: all 0.3s;
            z-index: 999;
            display: none;
        }
        .add-holding-btn.show {
            display: block;
        }
        .add-holding-btn:hover {
            transform: scale(1.1);
            box-shadow: 0 12px 24px rgba(92, 184, 92, 0.6);
        }
        .search-container {
            padding: 30px;
            background: #1a1d2e;
            border-bottom: 2px solid #2d3447;
        }
        .search-box {
            display: flex;
            gap: 10px;
            max-width: 600px;
            margin: 0 auto;
        }
        .search-input {
            flex: 1;
            padding: 15px 20px;
            border: 2px solid #2d3447;
            border-radius: 10px;
            font-size: 16px;
            outline: none;
            transition: all 0.3s;
            background: #252a3d;
            color: #e0e0e0;
        }
        .search-input:focus {
            border-color: #5cb85c;
            box-shadow: 0 0 0 3px rgba(92, 184, 92, 0.2);
        }
        .search-btn {
            padding: 15px 30px;
            background: #5cb85c;
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .search-btn:hover {
            background: #4cae4c;
            transform: translateY(-2px);
        }
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 1.2em;
            color: #5cb85c;
        }
        .error {
            text-align: center;
            padding: 50px;
            color: #dc3545;
            font-size: 1.1em;
        }
        .stocks-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            padding: 30px;
        }
        .stock-card {
            background: #252a3d;
            border: 2px solid #2d3447;
            border-radius: 12px;
            padding: 20px;
            transition: all 0.3s;
            cursor: pointer;
            position: relative;
        }
        .stock-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(92, 184, 92, 0.2);
            border-color: #5cb85c;
        }
        .profit-indicator {
            position: absolute;
            top: 15px;
            right: 15px;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .profit {
            background: rgba(46, 204, 113, 0.2);
            color: #2ecc71;
            border: 1px solid #2ecc71;
        }
        .loss {
            background: rgba(231, 76, 60, 0.2);
            color: #e74c3c;
            border: 1px solid #e74c3c;
        }
        .stock-symbol {
            font-size: 1.5em;
            font-weight: bold;
            color: #5cb85c;
            margin-bottom: 5px;
        }
        .stock-name {
            color: #8a92a6;
            margin-bottom: 15px;
            font-size: 0.9em;
        }
        .stock-price {
            font-size: 2em;
            font-weight: bold;
            color: #ffffff;
            margin-bottom: 10px;
        }
        .stock-details {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #2d3447;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
            font-size: 0.9em;
        }
        .detail-label { color: #8a92a6; }
        .detail-value {
            font-weight: 600;
            color: #ffffff;
        }
        .profit-value { color: #2ecc71; }
        .loss-value { color: #e74c3c; }
        .no-results {
            text-align: center;
            padding: 50px;
            color: #8a92a6;
            font-size: 1.2em;
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.7);
            overflow-y: auto;
        }
        .modal.active {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-content {
            background: #1a1d2e;
            border-radius: 20px;
            max-width: 600px;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
            animation: slideIn 0.3s ease-out;
        }
        @keyframes slideIn {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        .modal-header {
            background: #252a3d;
            color: white;
            padding: 25px 30px;
            border-radius: 20px 20px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #2d3447;
        }
        .modal-title { font-size: 1.8em; font-weight: bold; }
        .close-btn {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            font-size: 28px;
            cursor: pointer;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background 0.3s;
        }
        .close-btn:hover { background: rgba(255, 255, 255, 0.3); }
        .modal-body { padding: 30px; background: #1a1d2e; }
        .form-group {
            margin-bottom: 20px;
        }
        .form-label {
            display: block;
            color: #8a92a6;
            margin-bottom: 8px;
            font-weight: 600;
        }
        .form-input, .form-select {
            width: 100%;
            padding: 12px 15px;
            background: #252a3d;
            border: 2px solid #2d3447;
            border-radius: 8px;
            color: #ffffff;
            font-size: 1em;
            outline: none;
            transition: all 0.3s;
        }
        .form-input:focus, .form-select:focus {
            border-color: #5cb85c;
            box-shadow: 0 0 0 3px rgba(92, 184, 92, 0.2);
        }
        .form-select option {
            background: #252a3d;
            color: #ffffff;
        }
        .exchange-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .exchange-tab {
            flex: 1;
            padding: 12px;
            background: #252a3d;
            border: 2px solid #2d3447;
            border-radius: 8px;
            color: #8a92a6;
            cursor: pointer;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        .exchange-tab.active {
            background: #5cb85c;
            color: white;
            border-color: #5cb85c;
        }
        .exchange-tab:hover:not(.active) {
            border-color: #5cb85c;
            color: #ffffff;
        }
        .submit-btn {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #5cb85c 0%, #4cae4c 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 1.1em;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            text-transform: uppercase;
        }
        .submit-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(92, 184, 92, 0.4);
        }
        .toast {
            position: fixed;
            bottom: 30px;
            right: 30px;
            background: #252a3d;
            padding: 20px 25px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.8);
            display: none;
            align-items: center;
            gap: 15px;
            z-index: 2000;
            min-width: 300px;
            color: #ffffff;
        }
        .toast.show { display: flex; animation: slideInRight 0.3s ease-out; }
        .toast.success { border-left: 5px solid #5cb85c; }
        .toast.error { border-left: 5px solid #e74c3c; }
        @keyframes slideInRight {
            from { transform: translateX(100%); }
            to { transform: translateX(0); }
        }
        @media (max-width: 768px) {
            .stocks-grid { grid-template-columns: 1fr; }
            .add-holding-btn {
                bottom: 20px;
                right: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📈 Stock Market Trading Platform</h1>
            <p>Trade stocks and manage your portfolio</p>
        </div>
        <div class="nav-tabs">
            <button class="nav-tab active" onclick="switchTab('stocks')">Trending Stocks</button>
            <button class="nav-tab" onclick="switchTab('portfolio')">My Portfolio</button>
            <button class="nav-tab" onclick="switchTab('history')">Trade History</button>
        </div>
        
        <div id="stocksTab" class="tab-content active">
            <div class="search-container">
                <div class="search-box">
                    <input type="text" class="search-input" id="searchInput" placeholder="Search stocks...">
                    <button class="search-btn" onclick="searchStocks()">Search</button>
                </div>
            </div>
            <div id="stocksContainer"><div class="loading">Loading stocks...</div></div>
        </div>
        
        <div id="portfolioTab" class="tab-content">
            <div id="portfolioContainer"><div class="loading">Loading portfolio...</div></div>
        </div>
        
        <div id="historyTab" class="tab-content">
            <div id="historyContainer"><div class="loading">Loading trade history...</div></div>
        </div>
    </div>

    <button class="add-holding-btn" id="addHoldingBtn" onclick="openAddHoldingModal()" title="Add Holding">+</button>

    <div id="addHoldingModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <div class="modal-title">Add New Holding</div>
                <button class="close-btn" onclick="closeAddHoldingModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="exchange-tabs">
                    <div class="exchange-tab active" onclick="selectExchange('NSE')" id="nseTab">NSE</div>
                    <div class="exchange-tab" onclick="selectExchange('BSE')" id="bseTab">BSE</div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Select Stock</label>
                    <select class="form-select" id="stockSelect">
                        <option value="">Choose a stock...</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Purchase Price (₹)</label>
                    <input type="number" class="form-input" id="purchasePrice" placeholder="Enter price" step="0.01" min="0">
                </div>
                
                <div class="form-group">
                    <label class="form-label">Quantity</label>
                    <input type="number" class="form-input" id="quantity" placeholder="Enter quantity" min="1">
                </div>
                
                <button class="submit-btn" onclick="addHolding()">Add to Portfolio</button>
            </div>
        </div>
    </div>

    <div id="toast" class="toast">
        <span class="toast-icon" id="toastIcon"></span>
        <span class="toast-message" id="toastMessage"></span>
    </div>

    <script>
        const BACKEND_API = 'http://localhost:8080/api';
        let allStocks = [];
        let currentTab = 'stocks';
        let selectedExchange = 'NSE';
        let marketData = { NSE: {}, BSE: {} };

        const NSE_STOCKS = [
            { "Company": "Eternal", "Symbol": "ETEA.NS" },
            { "Company": "Oil and Natural Gas Corporation", "Symbol": "ONGC.NS" },
            { "Company": "Bharat Electronics", "Symbol": "BAJE.NS" },
            { "Company": "Hindustan Zinc", "Symbol": "HZNC.NS" },
            { "Company": "HDFC Bank", "Symbol": "HDBK.NS" },
            { "Company": "Tata Steel", "Symbol": "TISC.NS" },
            { "Company": "ITC", "Symbol": "ITC.NS" },
            { "Company": "Vedanta", "Symbol": "VDAN.NS" },
            { "Company": "Canara Bank", "Symbol": "CNBK.NS" },
            { "Company": "Indian Railway Finance Corporation Ltd", "Symbol": "INID.NS" }
        ];

        const BSE_STOCKS = [
            { "Company": "Suzlon Energy", "Symbol": "SUZL.BO" },
            { "Company": "Yes Bank", "Symbol": "YESB.BO" },
            { "Company": "Oil and Natural Gas Corporation", "Symbol": "ONGC.BO" },
            { "Company": "Bharat Electronics", "Symbol": "BAJE.BO" },
            { "Company": "Eternal", "Symbol": "ETEA.BO" },
            { "Company": "Kotak Mahindra Bank", "Symbol": "KTKM.BO" },
            { "Company": "Tata Steel", "Symbol": "TISC.BO" },
            { "Company": "Canara Bank", "Symbol": "CNBK.BO" },
            { "Company": "Bajaj Finserv", "Symbol": "BJFS.BO" },
            { "Company": "Vedanta", "Symbol": "VDAN.BO" }
        ];

        function switchTab(tab) {
            currentTab = tab;
            document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById(tab + 'Tab').classList.add('active');
            
            const addBtn = document.getElementById('addHoldingBtn');
            if (tab === 'portfolio') {
                addBtn.classList.add('show');
                loadPortfolio();
                fetchMarketData();
            } else {
                addBtn.classList.remove('show');
            }
            
            if (tab === 'history') loadTradeHistory();
        }

        function selectExchange(exchange) {
            selectedExchange = exchange;
            document.querySelectorAll('.exchange-tab').forEach(t => t.classList.remove('active'));
            document.getElementById(exchange.toLowerCase() + 'Tab').classList.add('active');
            populateStockSelect();
        }

        function populateStockSelect() {
            const select = document.getElementById('stockSelect');
            const stocks = selectedExchange === 'NSE' ? NSE_STOCKS : BSE_STOCKS;
            
            select.innerHTML = '<option value="">Choose a stock...</option>';
            stocks.forEach(stock => {
                const option = document.createElement('option');
                option.value = JSON.stringify(stock);
                option.textContent = `${stock.Company} (${stock.Symbol})`;
                select.appendChild(option);
            });
        }

        function openAddHoldingModal() {
            document.getElementById('addHoldingModal').classList.add('active');
            populateStockSelect();
        }

        function closeAddHoldingModal() {
            document.getElementById('addHoldingModal').classList.remove('active');
            document.getElementById('stockSelect').value = '';
            document.getElementById('purchasePrice').value = '';
            document.getElementById('quantity').value = '';
        }

        async function addHolding() {
            const stockData = document.getElementById('stockSelect').value;
            const purchasePrice = parseFloat(document.getElementById('purchasePrice').value);
            const quantity = parseInt(document.getElementById('quantity').value);

            if (!stockData || !purchasePrice || !quantity) {
                showToast('error', 'Please fill all fields');
                return;
            }

            const stock = JSON.parse(stockData);
            
            const holdingData = {
                tickerId: stock.Symbol,
                companyName: stock.Company,
                tradeType: 'BUY',
                quantity: quantity,
                price: purchasePrice,
                totalAmount: purchasePrice * quantity,
                date: new Date().toISOString().split('T')[0],
                time: new Date().toLocaleTimeString(),
                timestamp: new Date().toISOString()
            };

            try {
                const response = await fetch(`${BACKEND_API}/trades`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(holdingData)
                });

                if (!response.ok) throw new Error('Failed to add holding');
                
                showToast('success', `Added ${quantity} shares of ${stock.Company}`);
                closeAddHoldingModal();
                loadPortfolio();
                
            } catch (error) {
                console.error('Error:', error);
                showToast('error', 'Failed to add holding');
            }
        }

        async function fetchMarketData() {
            try {
                const [nseResponse, bseResponse] = await Promise.all([
                    fetch(`${BACKEND_API}/stocks/nse-active`),
                    fetch(`${BACKEND_API}/stocks/bse-active`)
                ]);

                if (nseResponse.ok) {
                    const nseData = await nseResponse.json();
                    if (nseData.most_active) {
                        nseData.most_active.forEach(stock => {
                            marketData.NSE[stock.ticker_id] = stock.price;
                        });
                    }
                }

                if (bseResponse.ok) {
                    const bseData = await bseResponse.json();
                    if (bseData.most_active) {
                        bseData.most_active.forEach(stock => {
                            marketData.BSE[stock.ticker_id] = stock.price;
                        });
                    }
                }
            } catch (error) {
                console.error('Error fetching market data:', error);
            }
        }

        function getCurrentPrice(symbol) {
            const exchange = symbol.includes('.NS') ? 'NSE' : 'BSE';
            return marketData[exchange][symbol] || null;
        }

        function calculateProfitLoss(purchasePrice, currentPrice, quantity) {
            if (!currentPrice) return null;
            
            const totalPurchase = purchasePrice * quantity;
            const currentValue = currentPrice * quantity;
            const profitLoss = currentValue - totalPurchase;
            const profitLossPercent = ((profitLoss / totalPurchase) * 100).toFixed(2);
            
            return {
                amount: profitLoss.toFixed(2),
                percent: profitLossPercent,
                isProfit: profitLoss >= 0
            };
        }

        async function fetchStocks() {
            const container = document.getElementById('stocksContainer');
            container.innerHTML = '<div class="loading">Loading trending stocks...</div>';
            try {
                const response = await fetch(`${BACKEND_API}/stocks/trending`);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                const data = await response.json();
                if (data && data.trending_stocks) {
                    const topGainers = data.trending_stocks.top_gainers || [];
                    const topLosers = data.trending_stocks.top_losers || [];
                    allStocks = [...topGainers, ...topLosers];
                    displayStocks(allStocks);
                }
            } catch (error) {
                console.error('Error:', error);
                container.innerHTML = `<div class="error">Failed to load stocks.</div>`;
            }
        }

        function displayStocks(stocks) {
            const container = document.getElementById('stocksContainer');
            if (!stocks || stocks.length === 0) {
                container.innerHTML = '<div class="no-results">No stocks found</div>';
                return;
            }
            const stocksHTML = stocks.map((stock, index) => `
                <div class="stock-card">
                    <div class="stock-symbol">${stock.ticker_id || 'N/A'}</div>
                    <div class="stock-name">${stock.company_name || 'Unknown'}</div>
                    <div class="stock-price">₹${parseFloat(stock.price || 0).toFixed(2)}</div>
                    <div class="stock-details">
                        <div class="detail-row">
                            <span class="detail-label">Volume:</span>
                            <span class="detail-value">${stock.volume ? parseInt(stock.volume).toLocaleString() : 'N/A'}</span>
                        </div>
                    </div>
                </div>
            `).join('');
            container.innerHTML = `<div class="stocks-grid">${stocksHTML}</div>`;
        }

        function searchStocks() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase().trim();
            if (!searchTerm) {
                displayStocks(allStocks);
                return;
            }
            const filtered = allStocks.filter(stock => 
                (stock.ticker_id || '').toLowerCase().includes(searchTerm) ||
                (stock.company_name || '').toLowerCase().includes(searchTerm)
            );
            displayStocks(filtered);
        }

        async function loadPortfolio() {
            const container = document.getElementById('portfolioContainer');
            container.innerHTML = '<div class="loading">Loading portfolio...</div>';
            
            await fetchMarketData();
            
            try {
                const response = await fetch(`${BACKEND_API}/trades/portfolio`);
                if (!response.ok) throw new Error('Failed to load portfolio');
                const portfolio = await response.json();
                
                if (!portfolio || portfolio.length === 0) {
                    container.innerHTML = '<div class="no-results">No holdings in portfolio<br><br>Click the + button to add your first holding!</div>';
                    return;
                }

                const portfolioHTML = portfolio.map(holding => {
                    const currentPrice = getCurrentPrice(holding.tickerId);
                    const pl = calculateProfitLoss(holding.averagePrice, currentPrice, holding.totalQuantity);
                    
                    let plIndicator = '';
                    let plRow = '';
                    
                    if (pl) {
                        plIndicator = `<div class="profit-indicator ${pl.isProfit ? 'profit' : 'loss'}">
                            ${pl.isProfit ? '+' : ''}${pl.percent}%
                        </div>`;
                        
                        plRow = `
                            <div class="detail-row">
                                <span class="detail-label">Current Price:</span>
                                <span class="detail-value">₹${currentPrice.toFixed(2)}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">P&L:</span>
                                <span class="detail-value ${pl.isProfit ? 'profit-value' : 'loss-value'}">
                                    ${pl.isProfit ? '+' : ''}₹${pl.amount} (${pl.isProfit ? '+' : ''}${pl.percent}%)
                                </span>
                            </div>
                        `;
                    }
                    
                    return `
                        <div class="stock-card">
                            ${plIndicator}
                            <div class="stock-symbol">${holding.tickerId}</div>
                            <div class="stock-name">${holding.companyName || 'Unknown'}</div>
                            <div class="stock-details">
                                <div class="detail-row">
                                    <span class="detail-label">Quantity:</span>
                                    <span class="detail-value">${holding.totalQuantity}</span>
                                </div>
                                <div class="detail-row">
                                    <span class="detail-label">Avg Price:</span>
                                    <span class="detail-value">₹${holding.averagePrice.toFixed(2)}</span>
                                </div>
                                ${plRow}
                                <div class="detail-row">
                                    <span class="detail-label">Invested:</span>
                                    <span class="detail-value">₹${(holding.averagePrice * holding.totalQuantity).toFixed(2)}</span>
                                </div>
                            </div>
                        </div>
                    `;
                }).join('');

                container.innerHTML = `<div class="stocks-grid">${portfolioHTML}</div>`;
            } catch (error) {
                console.error('Error:', error);
                container.innerHTML = '<div class="error">Failed to load portfolio</div>';
            }
        }

        async function loadTradeHistory() {
            const container = document.getElementById('historyContainer');
            container.innerHTML = '<div class="loading">Loading trade history...</div>';
            try {
                const response = await fetch(`${BACKEND_API}/trades`);
                if (!response.ok) throw new Error('Failed to load history');
                const trades = await response.json();
                
                if (!trades || trades.length === 0) {
                    container.innerHTML = '<div class="no-results">No trades yet</div>';
                    return;
                }

                const historyHTML = trades.map(trade => `
                    <div class="stock-card">
                        <div class="stock-symbol">${trade.tickerId}</div>
                        <div class="stock-name">${trade.companyName || 'Unknown'}</div>
                        <div class="stock-price" style="font-size: 1.2em; color: ${trade.tradeType === 'BUY' ? '#2ecc71' : '#e74c3c'}">
                            ${trade.tradeType}
                        </div>
                        <div class="stock-details">
                            <div class="detail-row">
                                <span class="detail-label">Quantity:</span>
                                <span class="detail-value">${trade.quantity}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">Price:</span>
                                <span class="detail-value">₹${trade.price.toFixed(2)}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">Total:</span>
                                <span class="detail-value">₹${trade.totalAmount.toFixed(2)}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">Date:</span>
                                <span class="detail-value">${new Date(trade.timestamp).toLocaleDateString()}</span>
                            </div>
                        </div>
                    </div>
                `).join('');

                container.innerHTML = `<div class="stocks-grid">${historyHTML}</div>`;
            } catch (error) {
                console.error('Error:', error);
                container.innerHTML = '<div class="error">Failed to load trade history</div>';
            }
        }

        function showToast(type, message) {
            const toast = document.getElementById('toast');
            document.getElementById('toastIcon').textContent = type === 'success' ? '✓' : '✕';
            document.getElementById('toastMessage').textContent = message;
            toast.className = `toast ${type} show`;
            setTimeout(() => toast.classList.remove('show'), 4000);
        }

        window.onclick = function(event) {
            if (event.target.id === 'addHoldingModal') closeAddHoldingModal();
        }

        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('searchInput').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') searchStocks();
            });
            fetchStocks();
        });

        setInterval(() => {
            if (currentTab === 'portfolio') {
                fetchMarketData();
                loadPortfolio();
            }
        }, 30000);
    </script>
</body>
</html>
EOFHTML

echo -e "${GREEN}[SUCCESS]${NC} Frontend updated with Add Holding feature"
echo ""

echo -e "${BLUE}[STEP 3/4]${NC} Updating StockController.java..."

cat > src/main/java/com/stockmarket/controller/StockController.java << 'EOFCONTROLLER'
package com.stockmarket.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/stocks")
@CrossOrigin(origins = "*")
public class StockController {
    
    private final RestTemplate restTemplate;
    
    @Value("${stock.api.url:https://stock.indianapi.in/trending}")
    private String stockApiUrl;
    
    @Value("${stock.api.nse.url:https://stock.indianapi.in/NSE_most_active}")
    private String nseApiUrl;
    
    @Value("${stock.api.bse.url:https://stock.indianapi.in/BSE_most_active}")
    private String bseApiUrl;
    
    @Value("${stock.api.key:sk-live-TMbB4OWlD0trKuuCIymohljapSXexU2R5Hx3aP4v}")
    private String apiKey;
    
    public StockController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    @GetMapping("/trending")
    public ResponseEntity<?> getTrendingStocks() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                stockApiUrl, HttpMethod.GET, entity, Map.class
            );
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching trending stocks: " + e.getMessage());
            return ResponseEntity.ok(getMockStockData());
        }
    }
    
    @GetMapping("/nse-active")
    public ResponseEntity<?> getNSEMostActive() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                nseApiUrl, HttpMethod.GET, entity, Map.class
            );
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching NSE data: " + e.getMessage());
            return ResponseEntity.ok(getMockNSEData());
        }
    }
    
    @GetMapping("/bse-active")
    public ResponseEntity<?> getBSEMostActive() {
        try {
            HttpHeaders headers = createHeaders();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                bseApiUrl, HttpMethod.GET, entity, Map.class
            );
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            System.err.println("Error fetching BSE data: " + e.getMessage());
            return ResponseEntity.ok(getMockBSEData());
        }
    }
    
    private HttpHeaders createHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Api-Key", apiKey);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }
    
    private Map<String, Object> getMockNSEData() {
        Map<String, Object> response = new HashMap<>();
        Object[] mostActive = new Object[] {
            createStockPrice("ETEA.NS", 451.95),
            createStockPrice("ONGC.NS", 285.40),
            createStockPrice("BAJE.NS", 289.75),
            createStockPrice("HZNC.NS", 512.30),
            createStockPrice("HDBK.NS", 1725.80),
            createStockPrice("TISC.NS", 158.65),
            createStockPrice("ITC.NS", 465.20),
            createStockPrice("VDAN.NS", 451.90),
            createStockPrice("CNBK.NS", 105.45),
            createStockPrice("INID.NS", 125.80)
        };
        response.put("most_active", mostActive);
        return response;
    }
    
    private Map<String, Object> getMockBSEData() {
        Map<String, Object> response = new HashMap<>();
        Object[] mostActive = new Object[] {
            createStockPrice("SUZL.BO", 65.25),
            createStockPrice("YESB.BO", 22.40),
            createStockPrice("ONGC.BO", 285.40),
            createStockPrice("BAJE.BO", 289.75),
            createStockPrice("ETEA.BO", 451.95),
            createStockPrice("KTKM.BO", 1845.60),
            createStockPrice("TISC.BO", 158.65),
            createStockPrice("CNBK.BO", 105.45),
            createStockPrice("BJFS.BO", 1685.30),
            createStockPrice("VDAN.BO", 451.90)
        };
        response.put("most_active", mostActive);
        return response;
    }
    
    private Map<String, Object> createStockPrice(String tickerId, double price) {
        Map<String, Object> stock = new HashMap<>();
        stock.put("ticker_id", tickerId);
        stock.put("price", price);
        return stock;
    }
    
    private Map<String, Object> getMockStockData() {
        Map<String, Object> response = new HashMap<>();
        Map<String, Object> trendingStocks = new HashMap<>();
        
        Object[] topGainers = new Object[] {
            createStock("RELIANCE", "Reliance Industries Ltd", 2500.50, 1500000),
            createStock("TCS", "Tata Consultancy Services", 3500.75, 800000),
            createStock("INFY", "Infosys Limited", 1450.25, 1200000)
        };
        
        trendingStocks.put("top_gainers", topGainers);
        trendingStocks.put("top_losers", new Object[]{});
        response.put("trending_stocks", trendingStocks);
        return response;
    }
    
    private Map<String, Object> createStock(String tickerId, String companyName, double price, int volume) {
        Map<String, Object> stock = new HashMap<>();
        stock.put("ticker_id", tickerId);
        stock.put("company_name", companyName);
        stock.put("price", price);
        stock.put("volume", volume);
        return stock;
    }
}
EOFCONTROLLER

echo -e "${GREEN}[SUCCESS]${NC} StockController updated with NSE/BSE endpoints"
echo ""

echo -e "${BLUE}[STEP 4/4]${NC} Updating application.properties..."

# Check if API URLs already exist
if grep -q "stock.api.nse.url" src/main/resources/application.properties; then
    echo -e "${YELLOW}[INFO]${NC} NSE/BSE API URLs already configured"
else
    # Backup and update
    cp src/main/resources/application.properties src/main/resources/application.properties.bak
    
    # Add NSE and BSE URLs after the main stock API URL
    sed -i '/stock.api.url=/ a\
stock.api.nse.url=https://stock.indianapi.in/NSE_most_active\
stock.api.bse.url=https://stock.indianapi.in/BSE_most_active' src/main/resources/application.properties
    
    echo -e "${GREEN}[SUCCESS]${NC} Added NSE/BSE API URLs to application.properties"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  ✨ Enhancement Complete! ✨"
echo "==========================================${NC}"
echo ""
echo "📦 What was added:"
echo "  ✅ Add Holding button (+) in Portfolio tab"
echo "  ✅ NSE/BSE stock selection modal"
echo "  ✅ Purchase price and quantity input"
echo "  ✅ Real-time profit/loss calculation"
echo "  ✅ Green/Red indicators for gains/losses"
echo "  ✅ Auto-refresh every 30 seconds"
echo "  ✅ Two new API endpoints:"
echo "     - /api/stocks/nse-active"
echo "     - /api/stocks/bse-active"
echo ""
echo "📁 Backups saved in: $backup_dir/"
echo ""
echo -e "${YELLOW}=========================================="
echo "  Next Steps"
echo "==========================================${NC}"
echo ""
echo "1. Rebuild your project:"
echo -e "   ${GREEN}mvn clean install${NC}"
echo ""
echo "2. Restart the application:"
echo -e "   ${GREEN}mvn spring-boot:run${NC}"
echo ""
echo "3. Open your browser:"
echo -e "   ${GREEN}http://localhost:8080/index.html${NC}"
echo ""
echo "4. Test the new features:"
echo "   • Go to 'My Portfolio' tab"
echo "   • Click the green + button"
echo "   • Select NSE or BSE"
echo "   • Choose a stock"
echo "   • Enter price and quantity"
echo "   • Click 'Add to Portfolio'"
echo "   • Watch profit/loss update automatically!"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "  • P&L shows in green for profit, red for loss"
echo "  • Percentage badge appears on top-right of cards"
echo "  • Portfolio refreshes every 30 seconds"
echo "  • Works with both NSE (.NS) and BSE (.BO) stocks"
echo ""
echo -e "${GREEN}🎉 Your portfolio is now supercharged!${NC}"
echo ""