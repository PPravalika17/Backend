// Add to existing app.js - News functionality

/**
 * Load and display news and announcements
 */
async function loadNews() {
    const container = document.getElementById('newsContainer');
    container.innerHTML = '<div class="loading">Loading latest news and announcements...</div>';
    
    try {
        const response = await fetch(`${BACKEND_API}/news`);
        if (!response.ok) throw new Error('Failed to load news');
        
        const data = await response.json();
        console.log('News API Response:', data);
        
        // Handle different response structures
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

/**
 * Display news articles in grid format
 */
function displayNews(articles) {
    const container = document.getElementById('newsContainer');
    
    const newsHTML = articles.map(article => {
        // Parse published date
        let publishedDate = 'Recently';
        try {
            if (article.published_at || article.publishedAt) {
                const date = new Date(article.published_at || article.publishedAt);
                publishedDate = formatNewsDate(date);
            }
        } catch (e) {
            console.error('Error parsing date:', e);
        }
        
        // Get source
        const source = article.source || article.source_name || 'Market News';
        
        // Get URL
        const url = article.url || article.link || '#';
        
        // Truncate description if too long
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

/**
 * Format news date in a user-friendly way
 */
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

/**
 * Update switchTab function to handle news tab
 */
const originalSwitchTab = switchTab;
switchTab = function(tab) {
    originalSwitchTab(tab);
    
    if (tab === 'news') {
        loadNews();
    }
};

// Auto-refresh news every 5 minutes
setInterval(() => {
    if (currentTab === 'news') {
        loadNews();
    }
}, 300000);