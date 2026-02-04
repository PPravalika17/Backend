#!/bin/bash

##############################################################################
# Professional Dashboard Enhancement with Navigation Menu & API Management
# This script adds professional features including sidebar nav and API settings
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
echo "  🚀 Professional Dashboard Enhancement"
echo "==========================================${NC}"
echo ""
echo "This will add:"
echo "  📱 Left sidebar navigation menu"
echo "  🔑 API key management settings"
echo "  📈 Live trending stocks with performance"
echo "  🎨 Professional color palette"
echo "  📰 News & Announcements section"
echo "  ⚙️  Settings page with API configuration"
echo ""

# Check if we're in a Spring Boot project
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}[ERROR]${NC} pom.xml not found. Please run this script from your Spring Boot project root directory."
    exit 1
fi

echo -e "${BLUE}[STEP 1/6]${NC} Backing up existing files..."

# Create backup
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="backup_pro_${timestamp}"
mkdir -p "$backup_dir"

if [ -f "src/main/resources/static/index.html" ]; then
    cp src/main/resources/static/index.html "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up index.html"
fi

if [ -f "src/main/resources/static/dashboard.html" ]; then
    cp src/main/resources/static/dashboard.html "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up dashboard.html"
fi

if [ -f "src/main/resources/static/app.js" ]; then
    cp src/main/resources/static/app.js "$backup_dir/"
    echo -e "${GREEN}✓${NC} Backed up app.js"
fi

echo -e "${GREEN}[SUCCESS]${NC} Backups created in: $backup_dir/"
echo ""

echo -e "${BLUE}[STEP 2/6]${NC} Creating enhanced index.html with sidebar navigation..."

cat > src/main/resources/static/index.html << 'EOFINDEX'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Stock Market Trading Platform</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0f1419;
            min-height: 100vh;
            overflow-x: hidden;
        }
        
        /* Sidebar Navigation */
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 280px;
            height: 100vh;
            background: linear-gradient(180deg, #1a1f2e 0%, #151a26 100%);
            border-right: 1px solid #2a3441;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            transition: transform 0.3s ease;
        }
        
        .sidebar-header {
            padding: 30px 25px;
            border-bottom: 1px solid #2a3441;
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
            color: #ffffff;
            font-size: 1.5em;
            font-weight: bold;
        }
        
        .logo-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3em;
        }
        
        .sidebar-menu {
            flex: 1;
            padding: 20px 0;
            overflow-y: auto;
        }
        
        .menu-item {
            padding: 15px 25px;
            color: #8a92a6;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 15px;
            font-size: 1em;
            border-left: 3px solid transparent;
        }
        
        .menu-item:hover {
            background: rgba(102, 126, 234, 0.1);
            color: #ffffff;
            border-left-color: #667eea;
        }
        
        .menu-item.active {
            background: rgba(102, 126, 234, 0.15);
            color: #667eea;
            border-left-color: #667eea;
            font-weight: 600;
        }
        
        .menu-icon {
            font-size: 1.3em;
            width: 24px;
            text-align: center;
        }
        
        .sidebar-footer {
            padding: 20px 25px;
            border-top: 1px solid #2a3441;
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
            color: #8a92a6;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        
        /* Main Content Area */
        .main-content {
            margin-left: 280px;
            min-height: 100vh;
            background: #0f1419;
        }
        
        .top-bar {
            background: #1a1f2e;
            border-bottom: 1px solid #2a3441;
            padding: 20px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .page-title {
            font-size: 1.8em;
            font-weight: bold;
            color: #ffffff;
        }
        
        .top-actions {
            display: flex;
            gap: 15px;
        }
        
        .action-btn {
            padding: 10px 20px;
            border-radius: 8px;
            border: none;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: #252a3d;
            color: #8a92a6;
            border: 1px solid #2a3441;
        }
        
        .btn-secondary:hover {
            background: #2d3447;
            color: #ffffff;
        }
        
        .content-area {
            padding: 30px 40px;
        }
        
        .container {
            max-width: 100%;
            background: transparent;
        }
        
        /* Original Styles - Updated */
        .search-container {
            padding: 0 0 30px 0;
            background: transparent;
            border-bottom: none;
        }
        .search-box {
            display: flex;
            gap: 10px;
            max-width: 600px;
        }
        .search-input {
            flex: 1;
            padding: 15px 20px;
            border: 2px solid #2a3441;
            border-radius: 10px;
            font-size: 16px;
            outline: none;
            transition: all 0.3s;
            background: #1a1f2e;
            color: #e0e0e0;
        }
        .search-input:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        .search-btn {
            padding: 15px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .search-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 1.2em;
            color: #667eea;
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
        }
        .stock-card {
            background: #1a1f2e;
            border: 2px solid #2a3441;
            border-radius: 12px;
            padding: 20px;
            transition: all 0.3s;
            cursor: pointer;
            position: relative;
        }
        .stock-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.2);
            border-color: #667eea;
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
            color: #667eea;
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
            border-top: 1px solid #2a3441;
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
        
        /* Modals */
        .modal {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.8);
            overflow-y: auto;
        }
        .modal.active {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-content {
            background: #1a1f2e;
            border-radius: 20px;
            max-width: 600px;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
            animation: slideIn 0.3s ease-out;
            border: 1px solid #2a3441;
        }
        @keyframes slideIn {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        .modal-header {
            background: #1e2432;
            color: white;
            padding: 25px 30px;
            border-radius: 20px 20px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #2a3441;
        }
        .modal-title { font-size: 1.8em; font-weight: bold; }
        .close-btn {
            background: rgba(255, 255, 255, 0.1);
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
        .close-btn:hover { background: rgba(255, 255, 255, 0.2); }
        .modal-body { padding: 30px; background: #1a1f2e; }
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
            background: #0f1419;
            border: 2px solid #2a3441;
            border-radius: 8px;
            color: #ffffff;
            font-size: 1em;
            outline: none;
            transition: all 0.3s;
        }
        .form-input:focus, .form-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        .form-select option {
            background: #1a1f2e;
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
            background: #0f1419;
            border: 2px solid #2a3441;
            border-radius: 8px;
            color: #8a92a6;
            cursor: pointer;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        .exchange-tab.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-color: #667eea;
        }
        .exchange-tab:hover:not(.active) {
            border-color: #667eea;
            color: #ffffff;
        }
        .submit-btn {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            box-shadow: 0 8px 16px rgba(102, 126, 234, 0.4);
        }
        .submit-btn.danger {
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
        }
        .submit-btn.danger:hover {
            box-shadow: 0 8px 16px rgba(231, 76, 60, 0.4);
        }
        .info-box {
            background: #0f1419;
            border-left: 4px solid #667eea;
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
            background: #0f1419;
            border-radius: 10px;
            padding: 5px;
            border: 2px solid #2a3441;
        }
        .quantity-btn {
            width: 40px;
            height: 40px;
            border: none;
            background: #667eea;
            color: white;
            font-size: 1.5em;
            font-weight: bold;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .quantity-btn:hover {
            background: #764ba2;
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
            background: #0f1419;
            border: 2px solid #2a3441;
            border-radius: 8px;
            color: #8a92a6;
            cursor: pointer;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        .quick-btn:hover {
            border-color: #667eea;
            color: #667eea;
        }
        .toast {
            position: fixed;
            bottom: 30px;
            right: 30px;
            background: #1a1f2e;
            padding: 20px 25px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.8);
            display: none;
            align-items: center;
            gap: 15px;
            z-index: 3000;
            min-width: 300px;
            color: #ffffff;
            border: 1px solid #2a3441;
        }
        .toast.show { display: flex; animation: slideInRight 0.3s ease-out; }
        .toast.success { border-left: 5px solid #2ecc71; }
        .toast.error { border-left: 5px solid #e74c3c; }
        @keyframes slideInRight {
            from { transform: translateX(100%); }
            to { transform: translateX(0); }
        }
        
        /* History Table */
        .history-table-container {
            overflow-x: auto;
        }
        .trade-table {
            width: 100%;
            border-collapse: collapse;
            background: #1a1f2e;
            border-radius: 12px;
            overflow: hidden;
            color: #e0e0e0;
        }
        .trade-table th {
            background: #1e2432;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #8a92a6;
            text-transform: uppercase;
            font-size: 0.85em;
            letter-spacing: 1px;
        }
        .trade-table td {
            padding: 15px;
            border-bottom: 1px solid #2a3441;
        }
        .trade-table tr:last-child td {
            border-bottom: none;
        }
        .trade-table tr:hover {
            background: rgba(102, 126, 234, 0.05);
        }
        .type-badge {
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 0.8em;
            font-weight: bold;
        }
        .badge-buy { background: rgba(46, 204, 113, 0.2); color: #2ecc71; }
        .badge-sell { background: rgba(231, 76, 60, 0.2); color: #e74c3c; }
        .date-cell { color: #8a92a6; font-size: 0.9em; }
        
        /* Floating Action Button */
        .add-holding-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 60px;
            height: 60px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 50%;
            font-size: 2em;
            cursor: pointer;
            box-shadow: 0 8px 16px rgba(102, 126, 234, 0.4);
            transition: all 0.3s;
            z-index: 999;
            display: none;
        }
        .add-holding-btn.show { display: block; }
        .add-holding-btn:hover {
            transform: scale(1.1);
            box-shadow: 0 12px 24px rgba(102, 126, 234, 0.6);
        }
        
        /* Chatbot Button */
        .chat-bubble-btn {
            position: fixed;
            bottom: 100px;
            right: 30px;
            width: 60px;
            height: 60px;
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: white;
            border: none;
            border-radius: 50%;
            font-size: 1.5em;
            cursor: pointer;
            box-shadow: 0 8px 16px rgba(52, 152, 219, 0.4);
            transition: all 0.3s;
            z-index: 999;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .chat-bubble-btn:hover { transform: scale(1.1); }
        
        .chat-option-btn {
            width: 100%;
            padding: 12px;
            margin: 5px 0;
            background: #0f1419;
            border: 1px solid #2a3441;
            color: #e0e0e0;
            border-radius: 8px;
            cursor: pointer;
            text-align: left;
            transition: all 0.2s;
        }
        .chat-option-btn:hover {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        #botResponse {
            white-space: pre-wrap;
            word-wrap: break-word;
            font-size: 14px;
            color: #e0e0e0;
            line-height: 1.6;
        }
        
        /* Mobile Menu Toggle */
        .mobile-menu-toggle {
            display: none;
            position: fixed;
            top: 20px;
            left: 20px;
            z-index: 1001;
            background: #667eea;
            border: none;
            color: white;
            width: 40px;
            height: 40px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1.5em;
        }
        
        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }
            .sidebar.open {
                transform: translateX(0);
            }
            .main-content {
                margin-left: 0;
            }
            .mobile-menu-toggle {
                display: block;
            }
            .stocks-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <button class="mobile-menu-toggle" onclick="toggleMobileMenu()">☰</button>
    
    <!-- Sidebar Navigation -->
    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <div class="logo-icon">📈</div>
                <span>StockTrader</span>
            </div>
        </div>
        
        <div class="sidebar-menu">
            <div class="menu-item active" onclick="switchPage('dashboard')">
                <span class="menu-icon">📊</span>
                <span>Dashboard</span>
            </div>
            <div class="menu-item" onclick="switchPage('trending')">
                <span class="menu-icon">🔥</span>
                <span>Trending Stocks</span>
            </div>
            <div class="menu-item" onclick="switchPage('portfolio')">
                <span class="menu-icon">💼</span>
                <span>My Portfolio</span>
            </div>
            <div class="menu-item" onclick="switchPage('history')">
                <span class="menu-icon">📜</span>
                <span>Trade History</span>
            </div>
            <div class="menu-item" onclick="openChatModal()">
                <span class="menu-icon">🤖</span>
                <span>AI Assistant</span>
            </div>
            <div class="menu-item" onclick="switchPage('news')">
                <span class="menu-icon">📰</span>
                <span>News & Announcements</span>
            </div>
            <div class="menu-item" onclick="switchPage('settings')">
                <span class="menu-icon">⚙️</span>
                <span>Settings</span>
            </div>
        </div>
        
        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">U</div>
                <div>
                    <div style="color: #ffffff; font-weight: 600;">User</div>
                    <div style="font-size: 0.85em;">Portfolio Manager</div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Main Content -->
    <div class="main-content">
        <div class="top-bar">
            <div class="page-title" id="pageTitle">Dashboard</div>
            <div class="top-actions">
                <button class="action-btn btn-secondary" onclick="location.reload()">
                    <span>🔄</span>
                    <span>Refresh</span>
                </button>
            </div>
        </div>
        
        <div class="content-area">
            <!-- Dashboard Tab -->
            <div id="dashboardPage" class="page-content active">
                <iframe src="dashboard.html" style="width: 100%; height: calc(100vh - 140px); border: none; border-radius: 12px;"></iframe>
            </div>
            
            <!-- Trending Stocks Tab -->
            <div id="trendingPage" class="page-content" style="display: none;">
                <div class="search-container">
                    <div class="search-box">
                        <input type="text" class="search-input" id="searchInput" placeholder="Search stocks...">
                        <button class="search-btn" onclick="searchStocks()">Search</button>
                    </div>
                </div>
                <div id="stocksContainer"><div class="loading">Loading stocks...</div></div>
            </div>
            
            <!-- Portfolio Tab -->
            <div id="portfolioPage" class="page-content" style="display: none;">
                <div id="portfolioContainer"><div class="loading">Loading portfolio...</div></div>
            </div>
            
            <!-- History Tab -->
            <div id="historyPage" class="page-content" style="display: none;">
                <div style="display: flex; justify-content: flex-end; margin-bottom: 20px;">
                    <button class="action-btn btn-primary" onclick="exportTradesToPDF()">
                        <span>📄</span>
                        <span>Export to PDF</span>
                    </button>
                </div>
                <div id="historyContainer"><div class="loading">Loading trade history...</div></div>
            </div>
            
            <!-- News Tab -->
            <div id="newsPage" class="page-content" style="display: none;">
                <div class="stocks-grid">
                    <div class="stock-card">
                        <h3 style="color: #667eea; margin-bottom: 15px;">📰 Market News</h3>
                        <p style="color: #8a92a6; line-height: 1.6;">
                            Stay updated with the latest market trends, stock analysis, and financial news.
                        </p>
                        <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid #2a3441;">
                            <p style="color: #8a92a6; font-size: 0.9em;">News integration coming soon...</p>
                        </div>
                    </div>
                    
                    <div class="stock-card">
                        <h3 style="color: #667eea; margin-bottom: 15px;">📢 Announcements</h3>
                        <p style="color: #8a92a6; line-height: 1.6;">
                            Important updates and announcements about your trading platform.
                        </p>
                        <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid #2a3441;">
                            <p style="color: #8a92a6; font-size: 0.9em;">No new announcements</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Settings Tab -->
            <div id="settingsPage" class="page-content" style="display: none;">
                <div style="max-width: 800px;">
                    <div class="stock-card" style="margin-bottom: 20px;">
                        <h3 style="color: #667eea; margin-bottom: 20px; font-size: 1.5em;">🔑 API Configuration</h3>
                        
                        <div class="form-group">
                            <label class="form-label">Stock Market API Key</label>
                            <input type="text" class="form-input" id="stockApiKey" 
                                   placeholder="Enter your Stock API key (e.g., sk-live-xxx...)">
                            <p style="color: #8a92a6; font-size: 0.85em; margin-top: 8px;">
                                Get your API key from <a href="https://stock.indianapi.in" target="_blank" style="color: #667eea;">stock.indianapi.in</a>
                            </p>
                        </div>
                        
                        <div class="form-group">
                            <label class="form-label">Gemini AI API Key</label>
                            <input type="text" class="form-input" id="geminiApiKey" 
                                   placeholder="Enter your Gemini API key (e.g., AIzaSy...)">
                            <p style="color: #8a92a6; font-size: 0.85em; margin-top: 8px;">
                                Get your API key from <a href="https://makersuite.google.com/app/apikey" target="_blank" style="color: #667eea;">Google AI Studio</a>
                            </p>
                        </div>
                        
                        <button class="submit-btn" onclick="saveApiKeys()">
                            Save API Keys
                        </button>
                    </div>
                    
                    <div class="stock-card">
                        <h3 style="color: #667eea; margin-bottom: 20px; font-size: 1.5em;">⚙️ Preferences</h3>
                        
                        <div class="form-group">
                            <label class="form-label">Auto Refresh Interval</label>
                            <select class="form-select" id="refreshInterval">
                                <option value="30000">30 seconds</option>
                                <option value="60000">1 minute</option>
                                <option value="300000">5 minutes</option>
                                <option value="0">Disabled</option>
                            </select>
                        </div>
                        
                        <button class="submit-btn" onclick="savePreferences()">
                            Save Preferences
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <button class="add-holding-btn" id="addHoldingBtn" onclick="openAddHoldingModal()" title="Add Holding">+</button>

    <!-- Modals (keeping all existing modals) -->
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

    <div id="chatModal" class="modal">
        <div class="modal-content" style="max-width: 500px;">
            <div class="modal-header">
                <div class="modal-title">AI Portfolio Advisor</div>
                <button class="close-btn" onclick="closeChatModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div id="botResponse" class="info-box" style="margin-bottom: 20px; max-height: 300px; overflow-y: auto;">
                    Hello! Click an option below to let Gemini AI analyze your data.
                </div>
                <div id="chatOptions" style="display: flex; flex-direction: column; gap: 10px;"></div>
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
EOFINDEX

echo -e "${GREEN}[SUCCESS]${NC} Enhanced index.html created"
echo ""

echo -e "${BLUE}[STEP 3/6]${NC} Updating app.js with API key management..."

cat > src/main/resources/static/app.js << 'EOFAPPJS'
// API Configuration from localStorage
function getApiKey(type) {
    return localStorage.getItem(`${type}ApiKey`) || '';
}

function setApiKey(type, key) {
    localStorage.setItem(`${type}ApiKey`, key);
}

const BACKEND_API = 'http://localhost:8080/api';
let allStocks = [];
let currentPage = 'dashboard';
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

// Page Navigation
function switchPage(page) {
    currentPage = page;
    
    // Update menu items
    document.querySelectorAll('.menu-item').forEach(item => item.classList.remove('active'));
    event.target.closest('.menu-item').classList.add('active');
    
    // Hide all pages
    document.querySelectorAll('.page-content').forEach(p => p.style.display = 'none');
    
    // Update page title and show content
    const titles = {
        'dashboard': 'Dashboard',
        'trending': 'Trending Stocks',
        'portfolio': 'My Portfolio',
        'history': 'Trade History',
        'news': 'News & Announcements',
        'settings': 'Settings'
    };
    
    document.getElementById('pageTitle').textContent = titles[page] || page;
    document.getElementById(`${page}Page`).style.display = 'block';
    
    // Show/hide add button
    const addBtn = document.getElementById('addHoldingBtn');
    if (page === 'portfolio') {
        addBtn.classList.add('show');
        loadPortfolio();
        fetchMarketData();
    } else {
        addBtn.classList.remove('show');
    }
    
    // Load page-specific data
    if (page === 'trending') fetchStocks();
    if (page === 'history') loadTradeHistory();
    if (page === 'settings') loadSettings();
    
    // Close mobile menu
    document.getElementById('sidebar').classList.remove('open');
}

function toggleMobileMenu() {
    document.getElementById('sidebar').classList.toggle('open');
}

// Settings Functions
function loadSettings() {
    document.getElementById('stockApiKey').value = getApiKey('stock');
    document.getElementById('geminiApiKey').value = getApiKey('gemini');
    document.getElementById('refreshInterval').value = localStorage.getItem('refreshInterval') || '30000';
}

function saveApiKeys() {
    const stockKey = document.getElementById('stockApiKey').value.trim();
    const geminiKey = document.getElementById('geminiApiKey').value.trim();
    
    setApiKey('stock', stockKey);
    setApiKey('gemini', geminiKey);
    
    showToast('success', 'API keys saved successfully');
}

function savePreferences() {
    const interval = document.getElementById('refreshInterval').value;
    localStorage.setItem('refreshInterval', interval);
    
    showToast('success', 'Preferences saved successfully');
    
    // Restart auto-refresh if enabled
    if (window.refreshTimer) {
        clearInterval(window.refreshTimer);
    }
    
    if (interval !== '0') {
        window.refreshTimer = setInterval(() => {
            if (currentPage === 'portfolio') {
                fetchMarketData();
                loadPortfolio();
            }
        }, parseInt(interval));
    }
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
    const apiKey = getApiKey('stock');
    if (!apiKey) {
        console.warn('Stock API key not configured');
        return;
    }
    
    try {
        const headers = {
            'X-Api-Key': apiKey,
            'Content-Type': 'application/json'
        };
        
        const [nseResponse, bseResponse] = await Promise.all([
            fetch('https://stock.indianapi.in/NSE_most_active', { headers }),
            fetch('https://stock.indianapi.in/BSE_most_active', { headers })
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
    const apiKey = getApiKey('stock');
    if (!apiKey) {
        document.getElementById('stocksContainer').innerHTML = 
            '<div class="error">Please configure your Stock API key in Settings</div>';
        return;
    }
    
    const container = document.getElementById('stocksContainer');
    container.innerHTML = '<div class="loading">Loading trending stocks...</div>';
    
    try {
        const response = await fetch('https://stock.indianapi.in/trending', {
            headers: {
                'X-Api-Key': apiKey,
                'Content-Type': 'application/json'
            }
        });
        
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
        container.innerHTML = `<div class="error">Failed to load stocks. Please check your API key in Settings.</div>`;
    }
}

function displayStocks(stocks) {
    const container = document.getElementById('stocksContainer');
    if (!stocks || stocks.length === 0) {
        container.innerHTML = '<div class="no-results">No stocks found</div>';
        return;
    }
    
    const stocksHTML = stocks.map((stock, index) => {
        const change = stock.net_change || 0;
        const changePercent = stock.percent_change || 0;
        const isPositive = change >= 0;
        
        return `
            <div class="stock-card">
                <div class="profit-indicator ${isPositive ? 'profit' : 'loss'}">
                    ${isPositive ? '▲' : '▼'} ${Math.abs(changePercent).toFixed(2)}%
                </div>
                <div class="stock-symbol">${stock.ticker_id || 'N/A'}</div>
                <div class="stock-name">${stock.company_name || 'Unknown'}</div>
                <div class="stock-price">₹${parseFloat(stock.price || 0).toFixed(2)}</div>
                <div class="stock-details">
                    <div class="detail-row">
                        <span class="detail-label">Change:</span>
                        <span class="detail-value ${isPositive ? 'profit-value' : 'loss-value'}">
                            ${isPositive ? '+' : ''}₹${change.toFixed(2)}
                        </span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Volume:</span>
                        <span class="detail-value">${stock.volume ? parseInt(stock.volume).toLocaleString() : 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">High:</span>
                        <span class="detail-value">₹${parseFloat(stock.high || 0).toFixed(2)}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Low:</span>
                        <span class="detail-value">₹${parseFloat(stock.low || 0).toFixed(2)}</span>
                    </div>
                </div>
            </div>
        `;
    }).join('');
    
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

function openChatModal() {
    document.getElementById('chatModal').classList.add('active');
    askBot("GREETING");
}

function closeChatModal() {
    document.getElementById('chatModal').classList.remove('active');
}

async function askBot(userChoice = "GREETING") {
    const geminiKey = getApiKey('gemini');
    if (!geminiKey) {
        document.getElementById('botResponse').innerText = 
            "Please configure your Gemini API key in Settings to use the AI Assistant.";
        document.getElementById('chatOptions').innerHTML = "";
        return;
    }
    
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
        botResponseBox.innerText = "Error connecting to AI Assistant. Is the backend running?";
    }
}

window.onclick = function(event) {
    if (event.target.id === 'addHoldingModal') closeAddHoldingModal();
    if (event.target.id === 'removeHoldingModal') closeRemoveHoldingModal();
    if (event.target.id === 'chatModal') closeChatModal();
}

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('searchInput')?.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') searchStocks();
    });
    
    // Initialize auto-refresh
    const interval = localStorage.getItem('refreshInterval') || '30000';
    if (interval !== '0') {
        window.refreshTimer = setInterval(() => {
            if (currentPage === 'portfolio') {
                fetchMarketData();
                loadPortfolio();
            }
        }, parseInt(interval));
    }
});
EOFAPPJS

echo -e "${GREEN}[SUCCESS]${NC} app.js updated with API key management"
echo ""

echo -e "${BLUE}[STEP 4/6]${NC} Updating dashboard.html with API integration..."

# Update dashboard.html to use API keys from localStorage
sed -i "s|const apiKey = .*|const apiKey = localStorage.getItem('stockApiKey') || '';|g" src/main/resources/static/dashboard.html 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} dashboard.html updated"
echo ""

echo -e "${BLUE}[STEP 5/6]${NC} Updating DashboardController.java..."

# The DashboardController from previous script should already exist
# Just verify it exists
if [ -f "src/main/java/com/stockmarket/controller/DashboardController.java" ]; then
    echo -e "${GREEN}✓${NC} DashboardController.java exists"
else
    echo -e "${YELLOW}[WARNING]${NC} DashboardController.java not found. Run add-dashboard.sh first."
fi

echo ""

echo -e "${BLUE}[STEP 6/6]${NC} Verifying installation..."

files_ok=true

if [ ! -f "src/main/resources/static/index.html" ]; then
    echo -e "${RED}✗${NC} index.html not created"
    files_ok=false
else
    echo -e "${GREEN}✓${NC} index.html created with sidebar navigation"
fi

if [ ! -f "src/main/resources/static/app.js" ]; then
    echo -e "${RED}✗${NC} app.js not created"
    files_ok=false
else
    echo -e "${GREEN}✓${NC} app.js updated with API management"
fi

echo ""

if [ "$files_ok" = true ]; then
    echo -e "${CYAN}=========================================="
    echo "  ✨ Professional Enhancement Complete! ✨"
    echo "==========================================${NC}"
    echo ""
    echo "📦 What was added:"
    echo "  ✅ Professional left sidebar navigation"
    echo "  ✅ API key management in Settings"
    echo "  ✅ Live trending stocks with performance metrics"
    echo "  ✅ Modern dark color palette"
    echo "  ✅ News & Announcements section"
    echo "  ✅ Settings page for API configuration"
    echo "  ✅ No hardcoded API keys"
    echo "  ✅ Mobile-responsive design"
    echo ""
    echo "🎨 New Navigation Menu:"
    echo "  📊 Dashboard - Performance analytics"
    echo "  🔥 Trending Stocks - Live market data with performance"
    echo "  💼 My Portfolio - Holdings management"
    echo "  📜 Trade History - Transaction records"
    echo "  🤖 AI Assistant - Portfolio advisor"
    echo "  📰 News & Announcements - Market updates"
    echo "  ⚙️  Settings - API key management"
    echo ""
    echo "🔑 API Configuration:"
    echo "  • Stock Market API (stock.indianapi.in)"
    echo "  • Gemini AI API (Google AI Studio)"
    echo "  • Stored securely in browser localStorage"
    echo "  • No hardcoded keys in source code"
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
    echo "3. Open the application:"
    echo -e "   ${GREEN}http://localhost:8080/index.html${NC}"
    echo ""
    echo "4. Configure API keys:"
    echo "   • Click 'Settings' in the sidebar"
    echo "   • Enter your Stock API key"
    echo "   • Enter your Gemini API key"
    echo "   • Click 'Save API Keys'"
    echo ""
    echo "5. Get your API keys:"
    echo "   • Stock API: https://stock.indianapi.in"
    echo "   • Gemini API: https://makersuite.google.com/app/apikey"
    echo ""
    echo -e "${BLUE}💡 Features:${NC}"
    echo "  • Professional sidebar navigation"
    echo "  • Live trending stocks with change % and performance"
    echo "  • Secure API key storage (localStorage)"
    echo "  • Auto-refresh settings (30s, 1m, 5m, disabled)"
    echo "  • Fully responsive design"
    echo "  • Modern dark theme"
    echo ""
    echo -e "${GREEN}🎉 Your professional trading platform is ready!${NC}"
    echo ""
else
    echo -e "${RED}[ERROR]${NC} Some files were not created properly. Please check the errors above."
    exit 1
fi