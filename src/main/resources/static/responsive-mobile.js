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

(function() {
    function fixChatbotClose() {
        const chatModal = document.getElementById('chatModal');
        const closeBtn = document.querySelector('.chat-close-btn');
        const chatFab = document.querySelector('.chat-fab');
        
        if (!chatModal) return;
        
        if (closeBtn) {
            closeBtn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                chatModal.style.display = 'none';
                if (chatFab) chatFab.style.display = 'flex';
            });
            
            closeBtn.addEventListener('touchend', function(e) {
                e.preventDefault();
                e.stopPropagation();
                chatModal.style.display = 'none';
                if (chatFab) chatFab.style.display = 'flex';
            });
        }
        
        if (chatFab) {
            chatFab.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                chatModal.style.display = 'block';
                chatFab.style.display = 'none';
            });
            
            chatFab.addEventListener('touchend', function(e) {
                e.preventDefault();
                e.stopPropagation();
                chatModal.style.display = 'block';
                chatFab.style.display = 'none';
            });
        }
        
        const modalHeader = chatModal.querySelector('.chat-header');
        if (modalHeader) {
            modalHeader.addEventListener('touchstart', function(e) {
                e.stopPropagation();
            });
        }
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(fixChatbotClose, 500);
        });
    } else {
        setTimeout(fixChatbotClose, 500);
    }
    
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.addedNodes.length) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.id === 'chatModal' || (node.querySelector && node.querySelector('#chatModal'))) {
                        setTimeout(fixChatbotClose, 100);
                    }
                });
            }
        });
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
})();
