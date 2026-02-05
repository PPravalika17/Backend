#!/bin/bash

set -e

echo "======================================"
echo "Responsive News Integration Script"
echo "======================================"
echo ""

STATIC_DIR="."
INDEX_HTML="${STATIC_DIR}/index.html"
APP_JS="${STATIC_DIR}/app.js"
RESPONSIVE_CSS="${STATIC_DIR}/responsive-mobile.css"
RESPONSIVE_JS="${STATIC_DIR}/responsive-mobile.js"

if [ ! -f "$INDEX_HTML" ]; then
    echo "ERROR: index.html not found in current directory!"
    echo "Please run this script from the static directory."
    exit 1
fi

echo "[1/7] Creating backup files..."
cp "$INDEX_HTML" "${INDEX_HTML}.backup.$(date +%Y%m%d_%H%M%S)"
if [ -f "$APP_JS" ]; then
    cp "$APP_JS" "${APP_JS}.backup.$(date +%Y%m%d_%H%M%S)"
fi
echo "✓ Backups created with timestamp"
echo ""

echo "[2/7] Creating responsive-mobile.css..."
cat > "$RESPONSIVE_CSS" << 'EOFCSS'
@media (max-width: 1024px) {
    .vertical-nav {
        width: 200px;
    }
    
    .main-content {
        margin-left: 200px;
    }
}

@media (max-width: 768px) {
    .vertical-nav {
        width: 80px;
        transition: width 0.3s ease;
    }
    
    .vertical-nav:hover {
        width: 250px;
    }
    
    .nav-header h1 {
        font-size: 0;
        transition: font-size 0.3s ease;
    }
    
    .nav-header h1::before {
        content: "ST";
        font-size: 1.5em;
    }
    
    .vertical-nav:hover .nav-header h1 {
        font-size: 1.5em;
    }
    
    .vertical-nav:hover .nav-header h1::before {
        content: "";
    }
    
    .nav-header p {
        display: none;
    }
    
    .vertical-nav:hover .nav-header p {
        display: block;
    }
    
    .nav-item {
        padding: 18px 10px;
        justify-content: center;
    }
    
    .vertical-nav:hover .nav-item {
        padding: 18px 25px;
        justify-content: flex-start;
    }
    
    .nav-item-icon {
        margin-right: 0;
        font-size: 1.5em;
    }
    
    .vertical-nav:hover .nav-item-icon {
        margin-right: 15px;
        font-size: 1.3em;
    }
    
    .nav-item span:not(.nav-item-icon) {
        display: none;
    }
    
    .vertical-nav:hover .nav-item span:not(.nav-item-icon) {
        display: inline;
    }
    
    .main-content {
        margin-left: 80px;
        padding: 20px;
    }
    
    .user-info span {
        display: none;
    }
    
    .vertical-nav:hover .user-info span {
        display: inline;
    }
}

@media (max-width: 480px) {
    .vertical-nav {
        position: fixed;
        left: -250px;
        width: 250px;
        z-index: 2000;
        transition: left 0.3s ease;
    }
    
    .vertical-nav.mobile-open {
        left: 0;
        box-shadow: 4px 0 20px rgba(0, 0, 0, 0.5);
    }
    
    .vertical-nav .nav-header h1 {
        font-size: 1.5em;
    }
    
    .vertical-nav .nav-header h1::before {
        content: "";
    }
    
    .vertical-nav .nav-header p {
        display: block;
    }
    
    .vertical-nav .nav-item {
        padding: 18px 25px;
        justify-content: flex-start;
    }
    
    .vertical-nav .nav-item-icon {
        margin-right: 15px;
        font-size: 1.3em;
    }
    
    .vertical-nav .nav-item span:not(.nav-item-icon) {
        display: inline;
    }
    
    .vertical-nav .user-info span {
        display: inline;
    }
    
    .main-content {
        margin-left: 0;
        padding: 15px;
        width: 100%;
    }
    
    .mobile-menu-btn {
        display: block !important;
        position: fixed;
        top: 15px;
        left: 15px;
        z-index: 1999;
        background: #5cb85c;
        color: white;
        border: none;
        border-radius: 8px;
        padding: 12px 15px;
        font-size: 1.5em;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(92, 184, 92, 0.4);
        transition: all 0.3s;
    }
    
    .mobile-menu-btn:active {
        transform: scale(0.95);
    }
    
    .mobile-overlay {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1999;
    }
    
    .mobile-overlay.active {
        display: block;
    }
    
    .content-header {
        padding: 20px;
        margin-top: 50px;
    }
    
    .content-header h1 {
        font-size: 1.5em;
    }
    
    .content-header p {
        font-size: 0.9em;
    }
    
    .search-box {
        flex-direction: column;
    }
    
    .search-input {
        width: 100%;
        font-size: 14px;
    }
    
    .search-btn {
        width: 100%;
        font-size: 14px;
    }
    
    .stocks-grid {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .stock-card {
        padding: 18px;
    }
    
    .portfolio-stats {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .stat-card {
        padding: 18px;
    }
    
    .portfolio-grid {
        grid-template-columns: 1fr;
    }
    
    .modal-content {
        width: 95%;
        margin: 20px auto;
        max-height: 90vh;
        overflow-y: auto;
    }
    
    .modal-header h2 {
        font-size: 1.3em;
    }
    
    .form-row {
        flex-direction: column;
    }
    
    .form-group {
        width: 100%;
    }
    
    .btn-group {
        flex-direction: column;
        gap: 10px;
    }
    
    .btn-group .btn {
        width: 100%;
    }
}

.mobile-menu-btn {
    display: none;
}

@media (max-width: 360px) {
    .content-header h1 {
        font-size: 1.3em;
    }
    
    .stock-card {
        padding: 15px;
    }
    
    .stat-card {
        padding: 15px;
    }
    
    .nav-header h1 {
        font-size: 1.3em;
    }
}

@media (min-width: 481px) and (max-width: 768px) {
    .stocks-grid {
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    }
    
    .portfolio-stats {
        grid-template-columns: repeat(2, 1fr);
    }
}

@media (max-width: 768px) {
    .history-table-container {
        overflow-x: auto;
    }
    
    .history-table {
        min-width: 600px;
    }
    
    .trade-details {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .detail-item {
        padding: 12px;
    }
    
    #chatModal {
        width: 95%;
        right: 2.5%;
        bottom: 70px;
        max-height: 70vh;
    }
    
    .chat-fab {
        bottom: 15px;
        right: 15px;
        width: 55px;
        height: 55px;
        font-size: 1.5em;
    }
    
    .summary-grid {
        grid-template-columns: 1fr;
    }
    
    .warning-message {
        flex-direction: column;
        text-align: center;
        gap: 10px;
    }
}

@media (max-width: 480px) {
    .toast {
        bottom: 80px;
        left: 10px;
        right: 10px;
        width: auto;
        min-width: auto;
        max-width: none;
    }
    
    .file-input-wrapper {
        padding: 15px;
    }
    
    .import-format-list {
        font-size: 0.85em;
    }
    
    .action-buttons {
        flex-direction: column;
        gap: 10px;
    }
    
    .action-buttons .btn {
        width: 100%;
    }
}

.news-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 25px;
}

.news-card {
    background: #252a3d;
    border: 2px solid #2d3447;
    border-radius: 12px;
    padding: 25px;
    transition: all 0.3s;
    display: flex;
    flex-direction: column;
    position: relative;
    overflow: hidden;
}

.news-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 25px rgba(92, 184, 92, 0.2);
    border-color: #5cb85c;
}

.news-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 4px;
    height: 100%;
    background: linear-gradient(180deg, #5cb85c 0%, #4cae4c 100%);
}

.news-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
    padding-bottom: 12px;
    border-bottom: 1px solid #2d3447;
}

.news-source {
    padding: 6px 14px;
    background: rgba(92, 184, 92, 0.2);
    border-radius: 12px;
    font-size: 0.8em;
    color: #5cb85c;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.news-date {
    color: #8a92a6;
    font-size: 0.85em;
    font-weight: 500;
}

.news-title {
    color: #ffffff;
    font-size: 1.25em;
    font-weight: 700;
    margin-bottom: 15px;
    line-height: 1.4;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.news-description {
    color: #8a92a6;
    line-height: 1.7;
    margin-bottom: 20px;
    flex: 1;
    font-size: 0.95em;
}

.news-footer {
    margin-top: auto;
    padding-top: 15px;
    border-top: 1px solid #2d3447;
}

.news-read-more {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: #5cb85c;
    text-decoration: none;
    font-weight: 600;
    font-size: 0.95em;
    transition: all 0.3s;
    padding: 8px 16px;
    border-radius: 8px;
    background: rgba(92, 184, 92, 0.1);
}

.news-read-more:hover {
    background: rgba(92, 184, 92, 0.2);
    color: #4cae4c;
    transform: translateX(5px);
}

.external-link-icon {
    font-size: 1.1em;
    transition: transform 0.3s;
}

.news-read-more:hover .external-link-icon {
    transform: translate(3px, -3px);
}

@media (max-width: 1400px) {
    .news-grid {
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    }
}

@media (max-width: 1024px) {
    .news-grid {
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 20px;
    }
    
    .news-card {
        padding: 20px;
    }
}

@media (max-width: 768px) {
    .news-grid {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .news-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
    }
    
    .news-card {
        padding: 18px;
    }
    
    .news-title {
        font-size: 1.1em;
    }
    
    .news-description {
        font-size: 0.9em;
    }
}

@media (max-width: 480px) {
    .news-card {
        padding: 15px;
    }
    
    .news-title {
        font-size: 1em;
        -webkit-line-clamp: 3;
    }
    
    .news-source {
        font-size: 0.75em;
        padding: 5px 12px;
    }
    
    .news-date {
        font-size: 0.8em;
    }
    
    .news-description {
        font-size: 0.85em;
        line-height: 1.6;
    }
    
    .news-read-more {
        font-size: 0.9em;
        padding: 6px 14px;
    }
}
EOFCSS
echo "✓ responsive-mobile.css created"
echo ""

echo "[3/7] Adding CSS link to index.html..."
if grep -q "responsive-mobile.css" "$INDEX_HTML"; then
    echo "⚠ responsive-mobile.css already linked, skipping..."
else
    sed -i '/<\/head>/i \    <link rel="stylesheet" href="responsive-mobile.css">' "$INDEX_HTML"
    echo "✓ CSS link added to index.html"
fi
echo ""

echo "[4/7] Adding News nav item to index.html..."
if grep -q 'onclick="switchTab('\''news'\'')"' "$INDEX_HTML"; then
    echo "⚠ News nav item already exists, skipping..."
else
    sed -i '/<div class="nav-item" onclick="switchTab('\''history'\'')">/a \            <div class="nav-item" onclick="switchTab('\''news'\'')"><span class="nav-item-icon">&#128240;</span> News</div>' "$INDEX_HTML"
    echo "✓ News nav item added"
fi
echo ""

echo "[5/7] Adding News tab content to index.html..."
if grep -q 'id="newsTab"' "$INDEX_HTML"; then
    echo "⚠ News tab content already exists, skipping..."
else
    sed -i '/<div id="historyTab" class="tab-content">/i \        <div id="newsTab" class="tab-content">\n            <div class="content-header">\n                <h1>News & Announcements</h1>\n                <p>Latest market news and updates from Indian stock markets</p>\n            </div>\n\n            <div id="newsContainer">\n                <div class="loading">Loading latest news...</div>\n            </div>\n        </div>\n' "$INDEX_HTML"
    echo "✓ News tab content added"
fi
echo ""

echo "[6/7] Creating responsive-mobile.js with mobile menu and news..."
cat > "$RESPONSIVE_JS" << 'EOFJS'
function initMobileMenu() {
    const mobileBtn = document.createElement('button');
    mobileBtn.className = 'mobile-menu-btn';
    mobileBtn.innerHTML = '☰';
    mobileBtn.onclick = toggleMobileMenu;
    
    const overlay = document.createElement('div');
    overlay.className = 'mobile-overlay';
    overlay.onclick = closeMobileMenu;
    
    document.body.insertBefore(mobileBtn, document.body.firstChild);
    document.body.insertBefore(overlay, document.body.firstChild);
    
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', closeMobileMenu);
    });
}

function toggleMobileMenu() {
    const nav = document.querySelector('.vertical-nav');
    const overlay = document.querySelector('.mobile-overlay');
    const btn = document.querySelector('.mobile-menu-btn');
    
    nav.classList.toggle('mobile-open');
    overlay.classList.toggle('active');
    
    if (nav.classList.contains('mobile-open')) {
        btn.innerHTML = '✕';
    } else {
        btn.innerHTML = '☰';
    }
}

function closeMobileMenu() {
    const nav = document.querySelector('.vertical-nav');
    const overlay = document.querySelector('.mobile-overlay');
    const btn = document.querySelector('.mobile-menu-btn');
    
    nav.classList.remove('mobile-open');
    overlay.classList.remove('active');
    btn.innerHTML = '☰';
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMobileMenu);
} else {
    initMobileMenu();
}

window.addEventListener('resize', () => {
    if (window.innerWidth > 480) {
        closeMobileMenu();
    }
});

async function loadNews() {
    const container = document.getElementById('newsContainer');
    container.innerHTML = '<div class="loading">Loading latest news and announcements...</div>';
    
    try {
        const response = await fetch(`${BACKEND_API}/news`);
        if (!response.ok) throw new Error('Failed to load news');
        
        const data = await response.json();
        console.log('News API Response:', data);
        
        const newsArticles = data.news || data.articles || [];
        
        if (!newsArticles || newsArticles.length === 0) {
            container.innerHTML = `
                <div class="no-results">
                    <div class="no-results-icon">&#128240;</div>
                    <div>No news articles available at the moment</div>
                    <p style="margin-top: 10px; font-size: 0.9em;">Check back later for the latest market updates</p>
                </div>
            `;
            return;
        }
        
        displayNews(newsArticles);
        
    } catch (error) {
        console.error('Error loading news:', error);
        container.innerHTML = `
            <div class="error">
                Failed to load news. Please try again later.
            </div>
        `;
    }
}

function displayNews(articles) {
    const container = document.getElementById('newsContainer');
    
    const newsHTML = articles.map(article => {
        let publishedDate = 'Recently';
        try {
            if (article.published_at || article.publishedAt) {
                const date = new Date(article.published_at || article.publishedAt);
                publishedDate = formatNewsDate(date);
            }
        } catch (e) {
            console.error('Error parsing date:', e);
        }
        
        const source = article.source || article.source_name || 'Market News';
        const url = article.url || article.link || '#';
        
        let description = article.description || article.content || 'No description available';
        if (description.length > 200) {
            description = description.substring(0, 200) + '...';
        }
        
        return `
            <div class="news-card">
                <div class="news-header">
                    <div class="news-source">${source}</div>
                    <div class="news-date">${publishedDate}</div>
                </div>
                
                <h3 class="news-title">${article.title || 'Untitled'}</h3>
                
                <p class="news-description">${description}</p>
                
                <div class="news-footer">
                    ${url !== '#' ? `
                        <a href="${url}" target="_blank" class="news-read-more">
                            Read Full Article
                            <span class="external-link-icon">&#8599;</span>
                        </a>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    container.innerHTML = `<div class="news-grid">${newsHTML}</div>`;
}

function formatNewsDate(date) {
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) {
        return 'Just now';
    } else if (diffMins < 60) {
        return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
    } else if (diffHours < 24) {
        return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    } else if (diffDays < 7) {
        return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    } else {
        return date.toLocaleDateString('en-IN', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }
}

if (typeof switchTab !== 'undefined') {
    const originalSwitchTab = switchTab;
    switchTab = function(tab) {
        originalSwitchTab(tab);
        
        if (tab === 'news') {
            loadNews();
        }
    };
}

setInterval(() => {
    if (typeof currentTab !== 'undefined' && currentTab === 'news') {
        loadNews();
    }
}, 300000);
EOFJS
echo "✓ responsive-mobile.js created"
echo ""

echo "[7/7] Adding script tag for responsive-mobile.js..."
if grep -q "responsive-mobile.js" "$INDEX_HTML"; then
    echo "⚠ responsive-mobile.js already linked, skipping..."
else
    sed -i 's|<script src="app.js"></script>|<script src="app.js"></script>\n    <script src="responsive-mobile.js"></script>|' "$INDEX_HTML"
    echo "✓ Script tag added"
fi
echo ""

echo "======================================"
echo "✓ Integration Complete!"
echo "======================================"
echo ""
echo "Files created/modified:"
echo "  ✓ responsive-mobile.css (new - full responsive design)"
echo "  ✓ responsive-mobile.js (new - mobile menu + news)"
echo "  ✓ index.html (modified)"
echo ""
echo "Features added:"
echo "  ✓ Responsive navigation (collapses on tablet)"
echo "  ✓ Mobile hamburger menu (< 480px)"
echo "  ✓ News tab with responsive cards"
echo "  ✓ Touch-optimized UI for mobile"
echo "  ✓ Adaptive layouts for all screen sizes"
echo ""
echo "Backup files created with timestamp in current directory"
echo ""
echo "Test on different screen sizes:"
echo "  • Desktop: > 1024px"
echo "  • Tablet: 768px - 1024px"
echo "  • Mobile: < 768px"
echo "  • Small Mobile: < 480px"
echo ""