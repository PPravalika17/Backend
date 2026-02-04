#!/bin/bash

##############################################################################
# Add Remove Holdings Feature
# This script adds the ability to remove holdings with profit/loss preview
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${MAGENTA}=========================================="
echo "  Add Remove Holdings Feature"
echo "==========================================${NC}"
echo ""
echo "This will add:"
echo "  🗑️  Remove button (×) on each portfolio card"
echo "  📊 Preview profit/loss before removing"
echo "  💰 Show current market value"
echo "  ⚡ Quick remove options (25%, 50%, 75%, All)"
echo "  🔢 Custom quantity selector"
echo "  ✅ Confirmation before removal"
echo ""

# Check if we're in a Spring Boot project
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}[ERROR]${NC} pom.xml not found. Please run this script from your Spring Boot project root directory."
    exit 1
fi

echo -e "${BLUE}[STEP 1/3]${NC} Backing up existing files..."

# Create backup
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="backup_remove_${timestamp}"
mkdir -p "$backup_dir"

if [ -f "src/main/resources/static/index.html" ]; then
    cp src/main/resources/static/index.html "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up index.html"
fi

if [ -f "src/main/resources/static/app.js" ]; then
    cp src/main/resources/static/app.js "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up app.js"
fi

echo -e "${GREEN}[SUCCESS]${NC} Backups created in: $backup_dir/"
echo ""

echo -e "${BLUE}[STEP 2/3]${NC} Creating enhanced frontend files..."

# Create the combined HTML file
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
        .add-holding-btn.show { display: block; }
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
        .remove-btn {
            position: absolute;
            top: 15px;
            left: 15px;
            width: 30px;
            height: 30px;
            background: rgba(231, 76, 60, 0.2);
            color: #e74c3c;
            border: 2px solid #e74c3c;
            border-radius: 50%;
            font-size: 1.2em;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            z-index: 10;
        }
        .remove-btn:hover {
            background: #e74c3c;
            color: white;
            transform: scale(1.15);
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
        .form-group { margin-bottom: 20px; }
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
        .submit-btn.danger {
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
        }
        .submit-btn.danger:hover {
            box-shadow: 0 8px 16px rgba(231, 76, 60, 0.4);
        }
        .info-box {
            background: #252a3d;
            border-left: 4px solid #5cb85c;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .info-box.warning {
            border-left-color: #f39c12;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
        }
        .info-label {
            color: #8a92a6;
        }
        .info-value {
            font-weight: 600;
            color: #ffffff;
        }
        .quantity-selector {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 15px;
            margin: 20px 0;
        }
        .quantity-controls {
            display: flex;
            align-items: center;
            gap: 10px;
            background: #252a3d;
            border-radius: 10px;
            padding: 5px;
            border: 2px solid #2d3447;
        }
        .quantity-btn {
            width: 40px;
            height: 40px;
            border: none;
            background: #5cb85c;
            color: white;
            font-size: 1.5em;
            font-weight: bold;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .quantity-btn:hover {
            background: #4cae4c;
            transform: scale(1.1);
        }
        .quantity-btn:disabled {
            background: #555;
            cursor: not-allowed;
            transform: none;
        }
        .quantity-input {
            width: 80px;
            height: 40px;
            text-align: center;
            font-size: 1.2em;
            font-weight: bold;
            border: none;
            background: transparent;
            color: #ffffff;
        }
        .quick-actions {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .quick-btn {
            flex: 1;
            padding: 10px;
            background: #252a3d;
            border: 2px solid #2d3447;
            border-radius: 8px;
            color: #8a92a6;
            cursor: pointer;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        .quick-btn:hover {
            border-color: #5cb85c;
            color: #5cb85c;
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

    <div id="removeHoldingModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <div class="modal-title">Remove Holding</div>
                <button class="close-btn" onclick="closeRemoveHoldingModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="info-box">
                    <div class="info-row">
                        <span class="info-label">Stock:</span>
                        <span class="info-value" id="removeStockSymbol">-</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Company:</span>
                        <span class="info-value" id="removeCompanyName">-</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Holdings:</span>
                        <span class="info-value" id="removeCurrentQty">-</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Avg Purchase Price:</span>
                        <span class="info-value" id="removeAvgPrice">-</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Current Price:</span>
                        <span class="info-value" id="removeCurrentPrice">-</span>
                    </div>
                </div>

                <div class="quick-actions">
                    <button class="quick-btn" onclick="setRemoveQuantity(0.25)">25%</button>
                    <button class="quick-btn" onclick="setRemoveQuantity(0.5)">50%</button>
                    <button class="quick-btn" onclick="setRemoveQuantity(0.75)">75%</button>
                    <button class="quick-btn" onclick="setRemoveQuantity(1)">All</button>
                </div>

                <div class="form-group">
                    <label class="form-label">Quantity to Remove</label>
                    <div class="quantity-selector">
                        <div class="quantity-controls">
                            <button class="quantity-btn" onclick="decreaseRemoveQty()">−</button>
                            <input type="number" class="quantity-input" id="removeQuantity" value="1" min="1" oninput="updateRemoveSummary()">
                            <button class="quantity-btn" onclick="increaseRemoveQty()">+</button>
                        </div>
                    </div>
                </div>

                <div class="info-box warning">
                    <div class="info-row">
                        <span class="info-label">Removing:</span>
                        <span class="info-value" id="removingQty">1 shares</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Value at Current Price:</span>
                        <span class="info-value" id="removeValue">₹0.00</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Profit/Loss:</span>
                        <span class="info-value" id="removePL">₹0.00</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Remaining:</span>
                        <span class="info-value" id="remainingQty">- shares</span>
                    </div>
                </div>

                <button class="submit-btn danger" onclick="executeRemove()">Remove from Portfolio</button>
            </div>
        </div>
    </div>

    <div id="toast" class="toast">
        <span class="toast-icon" id="toastIcon"></span>
        <span class="toast-message" id="toastMessage"></span>
    </div>

    <script src="app.js"></script>
</body>
</html>
EOFHTML

echo -e "${GREEN}[SUCCESS]${NC} Created index.html with remove feature"
echo ""

echo -e "${BLUE}[STEP 3/3]${NC} Creating app.js with remove logic..."

# Check if static directory exists
mkdir -p src/main/resources/static

# Create app.js
cat << 'EOFJS' > src/main/resources/static/app.js
const BACKEND_API = 'http://localhost:8080/api';
let allStocks = [];
let currentTab = 'stocks';
let selectedExchange = 'NSE';
let marketData = { NSE: {}, BSE: {} };
let currentRemoveHolding = null;

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

function openRemoveHoldingModal(holding) {
    currentRemoveHolding = holding;
    const currentPrice = getCurrentPrice(holding.tickerId);
    
    document.getElementById('removeStockSymbol').textContent = holding.tickerId;
    document.getElementById('removeCompanyName').textContent = holding.companyName || 'N/A';
    document.getElementById('removeCurrentQty').textContent = `${holding.totalQuantity} shares`;
    document.getElementById('removeAvgPrice').textContent = `₹${holding.averagePrice.toFixed(2)}`;
    document.getElementById('removeCurrentPrice').textContent = currentPrice ? `₹${currentPrice.toFixed(2)}` : 'N/A';
    
    const removeQtyInput = document.getElementById('removeQuantity');
    removeQtyInput.value = 1;
    removeQtyInput.max = holding.totalQuantity;
    
    updateRemoveSummary();
    document.getElementById('removeHoldingModal').classList.add('active');
}

function closeRemoveHoldingModal() {
    document.getElementById('removeHoldingModal').classList.remove('active');
    currentRemoveHolding = null;
}

function setRemoveQuantity(percentage) {
    if (!currentRemoveHolding) return;
    
    const qty = Math.ceil(currentRemoveHolding.totalQuantity * percentage);
    document.getElementById('removeQuantity').value = qty;
    updateRemoveSummary();
}

function increaseRemoveQty() {
    const input = document.getElementById('removeQuantity');
    const currentVal = parseInt(input.value) || 1;
    const maxVal = parseInt(input.max);
    
    if (currentVal < maxVal) {
        input.value = currentVal + 1;
        updateRemoveSummary();
    }
}

function decreaseRemoveQty() {
    const input = document.getElementById('removeQuantity');
    const currentVal = parseInt(input.value) || 1;
    
    if (currentVal > 1) {
        input.value = currentVal - 1;
        updateRemoveSummary();
    }
}

function updateRemoveSummary() {
    if (!currentRemoveHolding) return;
    
    const removeQty = parseInt(document.getElementById('removeQuantity').value) || 1;
    const currentPrice = getCurrentPrice(currentRemoveHolding.tickerId);
    const avgPrice = currentRemoveHolding.averagePrice;
    
    document.getElementById('removingQty').textContent = `${removeQty} shares`;
    
    if (currentPrice) {
        const currentValue = removeQty * currentPrice;
        const investedValue = removeQty * avgPrice;
        const profitLoss = currentValue - investedValue;
        const plPercent = ((profitLoss / investedValue) * 100).toFixed(2);
        
        document.getElementById('removeValue').textContent = `₹${currentValue.toFixed(2)}`;
        
        const plElement = document.getElementById('removePL');
        const plText = `${profitLoss >= 0 ? '+' : ''}₹${profitLoss.toFixed(2)} (${profitLoss >= 0 ? '+' : ''}${plPercent}%)`;
        plElement.textContent = plText;
        plElement.className = `info-value ${profitLoss >= 0 ? 'profit-value' : 'loss-value'}`;
    } else {
        document.getElementById('removeValue').textContent = 'N/A';
        document.getElementById('removePL').textContent = 'N/A';
    }
    
    const remaining = currentRemoveHolding.totalQuantity - removeQty;
    document.getElementById('remainingQty').textContent = `${remaining} shares`;
}

async function executeRemove() {
    if (!currentRemoveHolding) return;
    
    const removeQty = parseInt(document.getElementById('removeQuantity').value);
    const currentPrice = getCurrentPrice(currentRemoveHolding.tickerId) || currentRemoveHolding.averagePrice;
    
    if (removeQty <= 0 || removeQty > currentRemoveHolding.totalQuantity) {
        showToast('error', 'Invalid quantity');
        return;
    }
    
    const sellData = {
        tickerId: currentRemoveHolding.tickerId,
        companyName: currentRemoveHolding.companyName,
        tradeType: 'SELL',
        quantity: removeQty,
        price: currentPrice,
        totalAmount: removeQty * currentPrice,
        date: new Date().toISOString().split('T')[0],
        time: new Date().toLocaleTimeString(),
        timestamp: new Date().toISOString()
    };

    try {
        const response = await fetch(`${BACKEND_API}/trades`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(sellData)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to remove holding');
        }
        
        showToast('success', `Removed ${removeQty} shares of ${currentRemoveHolding.tickerId}`);
        closeRemoveHoldingModal();
        loadPortfolio();
        
    } catch (error) {
        console.error('Error:', error);
        showToast('error', error.message || 'Failed to remove holding');
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
                    <button class="remove-btn" onclick='openRemoveHoldingModal(${JSON.stringify(holding).replace(/'/g, "&apos;")})' title="Remove Holding">×</button>
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
    if (event.target.id === 'removeHoldingModal') closeRemoveHoldingModal();
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
EOFJS

echo -e "${GREEN}[SUCCESS]${NC} Created app.js with full functionality"
echo ""

echo -e "${CYAN}=========================================="
echo "  ✨ Remove Holdings Feature Added! ✨"
echo "==========================================${NC}"
echo ""
echo "📦 What was added:"
echo "  ✅ Remove button (×) on each portfolio card"
echo "  ✅ Modal with holding details"
echo "  ✅ Quick remove buttons (25%, 50%, 75%, All)"
echo "  ✅ Custom quantity selector with +/- buttons"
echo "  ✅ Real-time P&L preview while removing"
echo "  ✅ Current market price display"
echo "  ✅ Remaining shares calculator"
echo "  ✅ Color-coded profit/loss indicators"
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
echo "4. Test the new remove feature:"
echo "   • Go to 'My Portfolio' tab"
echo "   • Click the red × button on any holding"
echo "   • Try quick options: 25%, 50%, 75%, All"
echo "   • Use +/- buttons for custom quantity"
echo "   • Watch P&L update in real-time!"
echo "   • Click 'Remove from Portfolio'"
echo ""
echo -e "${BLUE}💡 Features:${NC}"
echo "  • Shows current market price vs your purchase price"
echo "  • Calculates exact profit/loss for the quantity being removed"
echo "  • Prevents removing more shares than you own"
echo "  • Updates portfolio automatically after removal"
echo "  • Green for profit, red for loss"
echo ""
echo -e "${GREEN}🎉 Your portfolio now has full management capabilities!${NC}"
echo ""