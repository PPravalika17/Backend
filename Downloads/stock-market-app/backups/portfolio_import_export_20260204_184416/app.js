const BACKEND_API = 'http://localhost:8080/api';
let allStocks = [];
let currentTab = 'trending';
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
    
    // Update navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    
    // Find and activate the clicked nav item
    const navItems = Array.from(document.querySelectorAll('.nav-item'));
    const activeNav = navItems.find(item => item.textContent.toLowerCase().includes(tab));
    if (activeNav) {
        activeNav.classList.add('active');
    }
    
    // Update content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tab + 'Tab').classList.add('active');
    
    // Show/hide FAB based on tab
    const fabAdd = document.getElementById('fabAdd');
    if (tab === 'portfolio') {
        fabAdd.classList.remove('hide');
        fabAdd.classList.add('show');
        loadPortfolio();
        fetchMarketData();
    } else {
        fabAdd.classList.remove('show');
        fabAdd.classList.add('hide');
    }
    
    if (tab === 'history') loadTradeHistory();
    if (tab === 'trending') fetchTrendingStocks();
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

async function fetchTrendingStocks() {
    const container = document.getElementById('stocksContainer');
    container.innerHTML = '<div class="loading">Loading trending stocks from market...</div>';
    
    try {
        const response = await fetch(`${BACKEND_API}/stocks/trending`);
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const data = await response.json();
        console.log('Trending API Response:', data);
        
        if (data && data.trending_stocks) {
            const topGainers = data.trending_stocks.top_gainers || [];
            const topLosers = data.trending_stocks.top_losers || [];
            const mostActive = data.trending_stocks.most_active || [];
            
            // Combine all stocks with their categories
            const categorizedStocks = [
                ...topGainers.map(s => ({...s, category: 'high-gainer'})),
                ...topLosers.map(s => ({...s, category: 'high-loser'})),
                ...mostActive.map(s => ({...s, category: 'most-active'}))
            ];
            
            allStocks = categorizedStocks;
            displayTrendingStocks(allStocks);
        } else {
            throw new Error('Invalid data structure');
        }
    } catch (error) {
        console.error('Error:', error);
        container.innerHTML = `<div class="error">Failed to load trending stocks. Please try again later.</div>`;
    }
}

function displayTrendingStocks(stocks) {
    const container = document.getElementById('stocksContainer');
    
    if (!stocks || stocks.length === 0) {
        container.innerHTML = `
            <div class="no-results">
                <div class="no-results-icon">📊</div>
                <div>No trending stocks found</div>
            </div>
        `;
        return;
    }
    
    const stocksHTML = stocks.map((stock) => {
        const price = parseFloat(stock.price || 0);
        const change = parseFloat(stock.change || 0);
        const changePercent = parseFloat(stock.change_percent || 0);
        const volume = parseInt(stock.volume || 0);
        const open = parseFloat(stock.open || 0);
        const high = parseFloat(stock.high || 0);
        const low = parseFloat(stock.low || 0);
        const prevClose = parseFloat(stock.prev_close || 0);
        
        // Determine price change class
        let changeClass = 'neutral';
        let changeIcon = '';
        if (change > 0) {
            changeClass = 'positive';
            changeIcon = '▲';
        } else if (change < 0) {
            changeClass = 'negative';
            changeIcon = '▼';
        }
        
        // Category badge
        let categoryBadge = '';
        let categoryLabel = '';
        if (stock.category === 'high-gainer') {
            categoryLabel = '🚀 Top Gainer';
        } else if (stock.category === 'high-loser') {
            categoryLabel = '📉 Top Loser';
        } else if (stock.category === 'most-active') {
            categoryLabel = '⚡ Most Active';
        }
        
        if (categoryLabel) {
            categoryBadge = `<div class="performance-badge ${stock.category}">${categoryLabel}</div>`;
        }
        
        const exchange = stock.exchange || (stock.ticker_id?.includes('.NS') ? 'NSE' : 'BSE');
        
        return `
            <div class="stock-card">
                ${categoryBadge}
                <div class="stock-header">
                    <div class="stock-symbol">${stock.ticker_id || 'N/A'}</div>
                    <div class="stock-exchange">${exchange}</div>
                </div>
                <div class="stock-name">${stock.company_name || 'Unknown Company'}</div>
                
                <div class="stock-price-section">
                    <div class="stock-price">₹${price.toFixed(2)}</div>
                    ${change !== 0 ? `
                        <div class="price-change ${changeClass}">
                            ${changeIcon} ₹${Math.abs(change).toFixed(2)} (${changePercent.toFixed(2)}%)
                        </div>
                    ` : ''}
                </div>
                
                <div class="stock-details">
                    ${volume > 0 ? `
                        <div class="detail-row">
                            <span class="detail-label">Volume:</span>
                            <span class="detail-value">${volume.toLocaleString()}</span>
                        </div>
                    ` : ''}
                    ${open > 0 ? `
                        <div class="detail-row">
                            <span class="detail-label">Open:</span>
                            <span class="detail-value">₹${open.toFixed(2)}</span>
                        </div>
                    ` : ''}
                    ${high > 0 ? `
                        <div class="detail-row">
                            <span class="detail-label">High:</span>
                            <span class="detail-value">₹${high.toFixed(2)}</span>
                        </div>
                    ` : ''}
                    ${low > 0 ? `
                        <div class="detail-row">
                            <span class="detail-label">Low:</span>
                            <span class="detail-value">₹${low.toFixed(2)}</span>
                        </div>
                    ` : ''}
                    ${prevClose > 0 ? `
                        <div class="detail-row">
                            <span class="detail-label">Prev Close:</span>
                            <span class="detail-value">₹${prevClose.toFixed(2)}</span>
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    container.innerHTML = `<div class="stocks-grid">${stocksHTML}</div>`;
}

function searchStocks() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase().trim();
    
    if (!searchTerm) {
        if (currentTab === 'trending') {
            displayTrendingStocks(allStocks);
        }
        return;
    }
    
    const filtered = allStocks.filter(stock => 
        (stock.ticker_id || '').toLowerCase().includes(searchTerm) ||
        (stock.company_name || '').toLowerCase().includes(searchTerm)
    );
    
    if (currentTab === 'trending') {
        displayTrendingStocks(filtered);
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
        isProfit: profitLoss >= 0,
        currentValue: currentValue.toFixed(2),
        totalInvested: totalPurchase.toFixed(2)
    };
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
            container.innerHTML = `
                <div class="no-results">
                    <div class="no-results-icon">💼</div>
                    <div>No holdings in portfolio</div>
                    <p style="margin-top: 10px; font-size: 0.9em;">Click the + button to add your first holding!</p>
                </div>
            `;
            return;
        }

        const portfolioHTML = portfolio.map(holding => {
            const currentPrice = getCurrentPrice(holding.tickerId);
            const pl = calculateProfitLoss(holding.averagePrice, currentPrice, holding.totalQuantity);
            
            let plIndicator = '';
            let plRow = '';
            
            if (pl) {
                plIndicator = `<div class="price-change ${pl.isProfit ? 'positive' : 'negative'}">
                    ${pl.isProfit ? '▲' : '▼'} ${pl.percent}%
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
            
            const exchange = holding.tickerId?.includes('.NS') ? 'NSE' : 'BSE';
            
            return `
                <div class="stock-card">
                    <div class="stock-header">
                        <div class="stock-symbol">${holding.tickerId}</div>
                        <div class="stock-exchange">${exchange}</div>
                    </div>
                    <div class="stock-name">${holding.companyName || 'Unknown'}</div>
                    
                    ${plIndicator ? `<div class="stock-price-section">${plIndicator}</div>` : ''}
                    
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
                    
                    <button class="remove-stock-btn" onclick='openRemoveStockModal(${JSON.stringify(holding).replace(/'/g, "\\'")})'>
                        🗑️ Remove from Portfolio
                    </button>
                </div>
            `;
        }).join('');

        container.innerHTML = `<div class="stocks-grid">${portfolioHTML}</div>`;
    } catch (error) {
        console.error('Error:', error);
        container.innerHTML = '<div class="error">Failed to load portfolio</div>';
    }
}

function openRemoveStockModal(holding) {
    currentRemoveHolding = holding;
    const modal = document.getElementById('removeStockModal');
    
    const currentPrice = getCurrentPrice(holding.tickerId);
    const exchange = holding.tickerId?.includes('.NS') ? 'NSE' : 'BSE';
    
    // Populate stock information
    document.getElementById('removeStockSymbol').textContent = holding.tickerId;
    document.getElementById('removeStockExchange').textContent = exchange;
    document.getElementById('removeStockName').textContent = holding.companyName || 'Unknown';
    document.getElementById('removeStockQuantity').textContent = holding.totalQuantity;
    document.getElementById('removeStockPurchasePrice').textContent = `₹${holding.averagePrice.toFixed(2)}`;
    
    const totalInvested = holding.averagePrice * holding.totalQuantity;
    document.getElementById('removeStockInvested').textContent = `₹${totalInvested.toFixed(2)}`;
    
    // Set current price
    document.getElementById('removeStockCurrentPrice').textContent = currentPrice 
        ? `₹${currentPrice.toFixed(2)}` 
        : 'Not Available';
    
    // Initialize quantity selector
    const quantityInput = document.getElementById('sellQuantity');
    const quantitySlider = document.getElementById('quantitySlider');
    
    quantityInput.max = holding.totalQuantity;
    quantityInput.value = holding.totalQuantity; // Default to selling all
    
    quantitySlider.max = holding.totalQuantity;
    quantitySlider.value = holding.totalQuantity;
    
    // Initial calculation
    updateSellCalculations();
    
    modal.classList.add('active');
}

function closeRemoveStockModal() {
    document.getElementById('removeStockModal').classList.remove('active');
    currentRemoveHolding = null;
}

function increaseQuantity() {
    const input = document.getElementById('sellQuantity');
    const max = parseInt(input.max);
    const current = parseInt(input.value) || 0;
    
    if (current < max) {
        input.value = current + 1;
        updateSellCalculations();
    }
}

function decreaseQuantity() {
    const input = document.getElementById('sellQuantity');
    const min = parseInt(input.min);
    const current = parseInt(input.value) || 0;
    
    if (current > min) {
        input.value = current - 1;
        updateSellCalculations();
    }
}

function updateQuantityFromSlider() {
    const slider = document.getElementById('quantitySlider');
    const input = document.getElementById('sellQuantity');
    input.value = slider.value;
    updateSellCalculations();
}

function setQuantityPreset(percentage) {
    if (!currentRemoveHolding) return;
    
    const totalQuantity = currentRemoveHolding.totalQuantity;
    const quantity = Math.max(1, Math.floor(totalQuantity * percentage / 100));
    
    const input = document.getElementById('sellQuantity');
    const slider = document.getElementById('quantitySlider');
    
    input.value = quantity;
    slider.value = quantity;
    
    updateSellCalculations();
}

function updateSellCalculations() {
    if (!currentRemoveHolding) return;
    
    const sellQuantity = parseInt(document.getElementById('sellQuantity').value) || 0;
    const slider = document.getElementById('quantitySlider');
    slider.value = sellQuantity;
    
    // Prevent invalid quantities
    if (sellQuantity < 1 || sellQuantity > currentRemoveHolding.totalQuantity) {
        return;
    }
    
    const currentPrice = getCurrentPrice(currentRemoveHolding.tickerId) || currentRemoveHolding.averagePrice;
    const purchasePrice = currentRemoveHolding.averagePrice;
    
    // Calculate values
    const totalSaleAmount = sellQuantity * currentPrice;
    const totalCost = sellQuantity * purchasePrice;
    const profitLoss = totalSaleAmount - totalCost;
    const isProfit = profitLoss >= 0;
    
    // Update summary
    document.getElementById('summaryQuantity').textContent = sellQuantity;
    document.getElementById('summarySalePrice').textContent = `₹${currentPrice.toFixed(2)}`;
    document.getElementById('summaryTotalSale').textContent = `₹${totalSaleAmount.toFixed(2)}`;
    document.getElementById('summaryTotalCost').textContent = `₹${totalCost.toFixed(2)}`;
    
    const plElement = document.getElementById('summaryProfitLoss');
    plElement.textContent = `${isProfit ? '+' : ''}₹${profitLoss.toFixed(2)}`;
    plElement.className = `summary-value ${isProfit ? 'profit' : 'loss'}`;
    
    // Show warning if selling all shares
    const warningMessage = document.getElementById('warningMessage');
    if (sellQuantity === currentRemoveHolding.totalQuantity) {
        warningMessage.style.display = 'flex';
    } else {
        warningMessage.style.display = 'none';
    }
}

async function confirmRemoveStock() {
    if (!currentRemoveHolding) {
        showToast('error', 'No stock selected');
        return;
    }
    
    const sellQuantity = parseInt(document.getElementById('sellQuantity').value);
    
    if (!sellQuantity || sellQuantity < 1 || sellQuantity > currentRemoveHolding.totalQuantity) {
        showToast('error', 'Invalid quantity');
        return;
    }
    
    const currentPrice = getCurrentPrice(currentRemoveHolding.tickerId) || currentRemoveHolding.averagePrice;
    
    // Use the new sell-from-portfolio endpoint
    const sellData = {
        tickerId: currentRemoveHolding.tickerId,
        quantity: sellQuantity,
        currentPrice: currentPrice
    };
    
    try {
        const response = await fetch(`${BACKEND_API}/trades/sell-from-portfolio`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(sellData)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to sell stock');
        }
        
        const result = await response.json();
        
        if (result.status === 'SUCCESS') {
            const totalCost = sellQuantity * currentRemoveHolding.averagePrice;
            const totalSale = sellQuantity * currentPrice;
            const profitLoss = totalSale - totalCost;
            const isProfit = profitLoss >= 0;
            
            let message = `Sold ${sellQuantity} shares of ${currentRemoveHolding.tickerId}`;
            if (isProfit) {
                message += ` with profit of ₹${profitLoss.toFixed(2)}`;
            } else {
                message += ` with loss of ₹${Math.abs(profitLoss).toFixed(2)}`;
            }
            
            showToast('success', message);
            closeRemoveStockModal();
            loadPortfolio();
            
            // Switch to portfolio tab to see updated holdings
            if (currentTab !== 'portfolio') {
                switchTab('portfolio');
            }
        } else {
            throw new Error(result.message || 'Failed to sell stock');
        }
        
    } catch (error) {
        console.error('Error:', error);
        showToast('error', error.message || 'Failed to sell stock');
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
            container.innerHTML = `
                <div class="no-trades">
                    <div class="no-trades-icon">📊</div>
                    <div class="no-trades-text">No trades yet</div>
                    <div class="no-trades-subtext">Start trading to see your history here</div>
                </div>
            `;
            return;
        }

        const sortedTrades = trades.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        // Create table HTML
        const tableHTML = `
            <div class="history-table-container">
                <table class="history-table">
                    <thead>
                        <tr>
                            <th>Date & Time</th>
                            <th>Stock</th>
                            <th>Type</th>
                            <th>Quantity</th>
                            <th>Price</th>
                            <th>Total Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${sortedTrades.map(trade => {
                            const tradeDate = new Date(trade.timestamp);
                            const dateStr = tradeDate.toLocaleDateString('en-IN', {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric'
                            });
                            const timeStr = tradeDate.toLocaleTimeString('en-IN', {
                                hour: '2-digit',
                                minute: '2-digit'
                            });

                            const tradeTypeClass = trade.tradeType === 'BUY' ? 'buy' : 'sell';

                            return `
                                <tr>
                                    <td>
                                        <div class="date-time-info">
                                            <div class="trade-date">${dateStr}</div>
                                            <div class="trade-time">${timeStr}</div>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="stock-info">
                                            <div class="stock-symbol">${trade.tickerId}</div>
                                            <div class="company-name">${trade.companyName || 'N/A'}</div>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="trade-type-badge ${tradeTypeClass}">${trade.tradeType}</span>
                                    </td>
                                    <td>${trade.quantity}</td>
                                    <td>₹${trade.price.toFixed(2)}</td>
                                    <td><span class="amount-value">₹${trade.totalAmount.toFixed(2)}</span></td>
                                </tr>
                            `;
                        }).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    } catch (error) {
        console.error('Error:', error);
        container.innerHTML = '<div class="error">Failed to load trade history</div>';
    }
}

async function exportTradesToPDF() {
    try {
        const response = await fetch(`${BACKEND_API}/trades`);
        if (!response.ok) throw new Error('Failed to load trades');
        const trades = await response.json();

        if (!trades || trades.length === 0) {
            showToast('error', 'No trades to export');
            return;
        }

        const sortedTrades = trades.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        doc.setFontSize(20);
        doc.setTextColor(40, 40, 40);
        doc.text('Trade History Report', 14, 22);

        doc.setFontSize(10);
        doc.setTextColor(100, 100, 100);
        doc.text(`Generated on: ${new Date().toLocaleString('en-IN')}`, 14, 30);

        const totalBuys = sortedTrades.filter(t => t.tradeType === 'BUY').length;
        const totalSells = sortedTrades.filter(t => t.tradeType === 'SELL').length;
        const totalBuyAmount = sortedTrades
            .filter(t => t.tradeType === 'BUY')
            .reduce((sum, t) => sum + t.totalAmount, 0);
        const totalSellAmount = sortedTrades
            .filter(t => t.tradeType === 'SELL')
            .reduce((sum, t) => sum + t.totalAmount, 0);

        doc.setFontSize(12);
        doc.setTextColor(40, 40, 40);
        doc.text('Summary:', 14, 40);

        doc.setFontSize(10);
        doc.text(`Total Trades: ${sortedTrades.length}`, 14, 47);
        doc.text(`Buy Orders: ${totalBuys}`, 14, 53);
        doc.text(`Sell Orders: ${totalSells}`, 14, 59);
        doc.text(`Total Buy Amount: Rs. ${totalBuyAmount.toFixed(2)}`, 14, 65);
        doc.text(`Total Sell Amount: Rs. ${totalSellAmount.toFixed(2)}`, 14, 71);

        const tableData = sortedTrades.map(trade => {
            const tradeDate = new Date(trade.timestamp);
            const dateStr = tradeDate.toLocaleDateString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
            const timeStr = tradeDate.toLocaleTimeString('en-IN', {
                hour: '2-digit',
                minute: '2-digit'
            });

            return [
                `${dateStr}\n${timeStr}`,
                `${trade.tickerId}\n${trade.companyName || 'N/A'}`,
                trade.tradeType,
                trade.quantity.toString(),
                `Rs. ${trade.price.toFixed(2)}`,
                `Rs. ${trade.totalAmount.toFixed(2)}`
            ];
        });

        doc.autoTable({
            startY: 80,
            head: [['Date & Time', 'Stock', 'Type', 'Quantity', 'Price', 'Total Amount']],
            body: tableData,
            theme: 'grid',
            headStyles: {
                fillColor: [45, 52, 71],
                textColor: [255, 255, 255],
                fontSize: 10,
                fontStyle: 'bold',
                halign: 'center'
            },
            bodyStyles: {
                fontSize: 9,
                cellPadding: 5
            },
            columnStyles: {
                0: { cellWidth: 35 },
                1: { cellWidth: 55 },
                2: { cellWidth: 20, halign: 'center' },
                3: { cellWidth: 25, halign: 'right' },
                4: { cellWidth: 25, halign: 'right' },
                5: { cellWidth: 30, halign: 'right' }
            },
            didParseCell: function(data) {
                if (data.column.index === 2 && data.cell.section === 'body') {
                    if (data.cell.raw === 'BUY') {
                        data.cell.styles.textColor = [46, 204, 113];
                        data.cell.styles.fontStyle = 'bold';
                    } else if (data.cell.raw === 'SELL') {
                        data.cell.styles.textColor = [231, 76, 60];
                        data.cell.styles.fontStyle = 'bold';
                    }
                }
            },
            margin: { top: 80 }
        });

        const pageCount = doc.internal.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.setTextColor(150, 150, 150);
            doc.text(
                `Page ${i} of ${pageCount}`,
                doc.internal.pageSize.getWidth() / 2,
                doc.internal.pageSize.getHeight() - 10,
                { align: 'center' }
            );
        }

        const filename = `Trade_History_${new Date().toISOString().split('T')[0]}.pdf`;
        doc.save(filename);

        showToast('success', 'PDF exported successfully');
    } catch (error) {
        console.error('Error exporting PDF:', error);
        showToast('error', 'Failed to export PDF');
    }
}

function showToast(type, message) {
    const toast = document.getElementById('toast');
    document.getElementById('toastIcon').textContent = type === 'success' ? '✓' : '✕';
    document.getElementById('toastMessage').textContent = message;
    toast.className = `toast ${type} show`;
    setTimeout(() => toast.classList.remove('show'), 4000);
}

function toggleChat() {
    const modal = document.getElementById('chatModal');
    if (modal) {
        modal.classList.toggle('active');
        if (modal.classList.contains('active')) {
            askBot("GREETING");
        }
    }
}

async function askBot(userChoice = "GREETING") {
    const botResponseBox = document.getElementById('botResponse');
    const optionsContainer = document.getElementById('chatOptions');

    if (userChoice !== "GREETING") {
        botResponseBox.innerHTML = "<i>Gemini is analyzing your portfolio... Please wait.</i>";
    }

    try {
        const response = await fetch(`${BACKEND_API}/chat/ask`, {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain' },
            body: userChoice
        });

        const data = await response.json();
        botResponseBox.innerText = data.botMessage;

        optionsContainer.innerHTML = "";
        data.options.forEach(optText => {
            const btn = document.createElement('button');
            btn.className = 'chat-option-btn';
            btn.style.width = "100%";
            btn.style.padding = "12px";
            btn.innerText = optText;
            btn.onclick = () => askBot(optText);
            optionsContainer.appendChild(btn);
        });

    } catch (error) {
        console.error('Chat Error:', error);
        if (botResponseBox) {
            botResponseBox.innerText = "Error connecting to AI Assistant. Is the backend running?";
        }
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    fetchTrendingStocks();
    
    // Add enter key support for search
    document.getElementById('searchInput')?.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') searchStocks();
    });
});

// Auto-refresh trending stocks every 2 minutes
setInterval(() => {
    if (currentTab === 'trending') {
        fetchTrendingStocks();
    }
}, 120000);

// Auto-refresh portfolio every 30 seconds
setInterval(() => {
    if (currentTab === 'portfolio') {
        fetchMarketData();
        loadPortfolio();
    }
}, 30000);
// ============================================
// ENHANCED CHAT FUNCTIONS
// ============================================

function toggleChat() {
    const modal = document.getElementById('chatModal');
    if (modal) {
        modal.classList.toggle('active');
        if (modal.classList.contains('active')) {
            askBot("GREETING");
        }
    }
}

async function askBot(userChoice = "GREETING") {
    const botResponseBox = document.getElementById('botResponse');
    const optionsContainer = document.getElementById('chatOptions');

    if (userChoice !== "GREETING") {
        botResponseBox.innerHTML = "<div class='ai-thinking'>🤖 Gemini is analyzing your data... Please wait.</div>";
    }

    try {
        const response = await fetch(`${BACKEND_API}/chat/ask`, {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain' },
            body: userChoice
        });

        const data = await response.json();
        
        // Format the bot message with better styling
        const formattedMessage = data.botMessage.replace(/\n/g, '<br>');
        botResponseBox.innerHTML = `<div class="bot-message-content">${formattedMessage}</div>`;

        // Clear and rebuild options
        optionsContainer.innerHTML = "";
        data.options.forEach(optText => {
            const btn = document.createElement('button');
            btn.className = 'chat-option-btn';
            btn.innerText = optText;
            btn.onclick = () => askBot(optText);
            optionsContainer.appendChild(btn);
        });

    } catch (error) {
        console.error('Chat Error:', error);
        if (botResponseBox) {
            botResponseBox.innerHTML = "<div class='error-message'>❌ Error connecting to AI Assistant. Please ensure the backend is running.</div>";
        }
    }
}
