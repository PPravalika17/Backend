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

        // Sort trades by timestamp (newest first)
        const sortedTrades = trades.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        const tableRows = sortedTrades.map(trade => {
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

            return `
                <tr>
                    <td class="date-cell">${dateStr}<br><small>${timeStr}</small></td>
                    <td><strong>${trade.tickerId}</strong><br><small>${trade.companyName || 'N/A'}</small></td>
                    <td><span class="type-badge badge-${trade.tradeType.toLowerCase()}">${trade.tradeType}</span></td>
                    <td style="text-align: right;">${trade.quantity}</td>
                    <td style="text-align: right;">₹${trade.price.toFixed(2)}</td>
                    <td style="text-align: right;"><strong>₹${trade.totalAmount.toFixed(2)}</strong></td>
                </tr>
            `;
        }).join('');

        const historyHTML = `
            <div class="history-table-container">
                <table class="trade-table">
                    <thead>
                        <tr>
                            <th>Date & Time</th>
                            <th>Stock</th>
                            <th>Type</th>
                            <th style="text-align: right;">Quantity</th>
                            <th style="text-align: right;">Price</th>
                            <th style="text-align: right;">Total Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${tableRows}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = historyHTML;
    } catch (error) {
        console.error('Error:', error);
        container.innerHTML = '<div class="error">Failed to load trade history</div>';
    }
}

async function exportTradesToPDF() {
    try {
        // Fetch trade data
        const response = await fetch(`${BACKEND_API}/trades`);
        if (!response.ok) throw new Error('Failed to load trades');
        const trades = await response.json();

        if (!trades || trades.length === 0) {
            showToast('error', 'No trades to export');
            return;
        }

        // Sort trades by timestamp (newest first)
        const sortedTrades = trades.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        // Initialize jsPDF
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        // Add title
        doc.setFontSize(20);
        doc.setTextColor(40, 40, 40);
        doc.text('Trade History Report', 14, 22);

        // Add generation date
        doc.setFontSize(10);
        doc.setTextColor(100, 100, 100);
        doc.text(`Generated on: ${new Date().toLocaleString('en-IN')}`, 14, 30);

        // Calculate summary statistics
        const totalBuys = sortedTrades.filter(t => t.tradeType === 'BUY').length;
        const totalSells = sortedTrades.filter(t => t.tradeType === 'SELL').length;
        const totalBuyAmount = sortedTrades
            .filter(t => t.tradeType === 'BUY')
            .reduce((sum, t) => sum + t.totalAmount, 0);
        const totalSellAmount = sortedTrades
            .filter(t => t.tradeType === 'SELL')
            .reduce((sum, t) => sum + t.totalAmount, 0);

        // Add summary section
        doc.setFontSize(12);
        doc.setTextColor(40, 40, 40);
        doc.text('Summary:', 14, 40);

        doc.setFontSize(10);
        doc.text(`Total Trades: ${sortedTrades.length}`, 14, 47);
        doc.text(`Buy Orders: ${totalBuys}`, 14, 53);
        doc.text(`Sell Orders: ${totalSells}`, 14, 59);
        doc.text(`Total Buy Amount: Rs. ${totalBuyAmount.toFixed(2)}`, 14, 65);
        doc.text(`Total Sell Amount: Rs. ${totalSellAmount.toFixed(2)}`, 14, 71);

        // Prepare table data
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

        // Add table using autoTable plugin
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
                // Color code BUY and SELL
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

        // Add footer with page numbers
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

        // Save the PDF
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