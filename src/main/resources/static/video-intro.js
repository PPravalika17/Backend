/**
 * Video Intro Handler
 * Manages the intro video playback and transition to main content
 */

(function() {
    'use strict';
    
    // Configuration
    const VIDEO_INTRO_KEY = 'stockpro_intro_seen';
    const SHOW_INTRO_EVERY_SESSION = false; // Set to true to show intro every time
    
    // Check if intro should be shown
    function shouldShowIntro() {
        if (SHOW_INTRO_EVERY_SESSION) {
            return true;
        }
        
        // Check sessionStorage (intro seen this session?)
        const seenThisSession = sessionStorage.getItem(VIDEO_INTRO_KEY);
        if (seenThisSession) {
            return false;
        }
        
        // Optionally check localStorage for permanent "don't show again"
        // Uncomment below to only show intro once ever:
        // const seenBefore = localStorage.getItem(VIDEO_INTRO_KEY);
        // if (seenBefore) return false;
        
        return true;
    }
    
    // Mark intro as seen
    function markIntroAsSeen() {
        sessionStorage.setItem(VIDEO_INTRO_KEY, 'true');
        // Uncomment to permanently mark as seen:
        // localStorage.setItem(VIDEO_INTRO_KEY, 'true');
    }
    
    // Initialize video intro
    function initVideoIntro() {
        const overlay = document.getElementById('videoIntroOverlay');
        const video = document.getElementById('introVideo');
        const skipBtn = document.getElementById('skipIntroBtn');
        const loadingIndicator = document.getElementById('videoLoading');
        
        if (!overlay || !video || !skipBtn) {
            console.error('Video intro elements not found');
            return;
        }
        
        // Don't show intro if already seen
        if (!shouldShowIntro()) {
            overlay.classList.add('hidden');
            document.body.classList.remove('intro-playing');
            return;
        }
        
        // Add class to prevent body scrolling
        document.body.classList.add('intro-playing');
        
        // Show loading indicator
        if (loadingIndicator) {
            loadingIndicator.classList.remove('hidden');
        }
        
        // Video loaded and can play
        video.addEventListener('canplay', function() {
            if (loadingIndicator) {
                loadingIndicator.classList.add('hidden');
            }
        });
        
        // Auto-play video
        const playPromise = video.play();
        
        if (playPromise !== undefined) {
            playPromise.then(() => {
                console.log('Video intro started playing');
                if (loadingIndicator) {
                    loadingIndicator.classList.add('hidden');
                }
            }).catch(error => {
                console.error('Auto-play failed:', error);
                // If autoplay fails (common on mobile), show a play button
                showPlayButton();
            });
        }
        
        // When video ends, fade out and hide
        video.addEventListener('ended', function() {
            endIntro();
        });
        
        // Skip button functionality
        skipBtn.addEventListener('click', function() {
            endIntro();
        });
        
        // Allow spacebar to skip
        document.addEventListener('keydown', function(e) {
            if (e.code === 'Space' && !overlay.classList.contains('fade-out')) {
                e.preventDefault();
                endIntro();
            }
        });
    }
    
    // Show play button if autoplay fails
    function showPlayButton() {
        const loadingIndicator = document.getElementById('videoLoading');
        const video = document.getElementById('introVideo');
        
        if (loadingIndicator) {
            loadingIndicator.innerHTML = `
                <div style="text-align: center;">
                    <button id="manualPlayBtn" style="
                        padding: 20px 40px;
                        background: linear-gradient(135deg, #5cb85c 0%, #4cae4c 100%);
                        color: white;
                        border: none;
                        border-radius: 50px;
                        font-size: 1.2em;
                        font-weight: 600;
                        cursor: pointer;
                        transition: all 0.3s;
                    ">
                        ▶ Play Intro
                    </button>
                    <div style="margin-top: 15px; color: #8a92a6; font-size: 0.9em;">
                        or press Skip to continue
                    </div>
                </div>
            `;
            loadingIndicator.classList.remove('hidden');
            
            const playBtn = document.getElementById('manualPlayBtn');
            if (playBtn) {
                playBtn.addEventListener('click', function() {
                    video.play();
                    loadingIndicator.classList.add('hidden');
                });
                
                playBtn.addEventListener('mouseenter', function() {
                    this.style.transform = 'scale(1.05)';
                    this.style.boxShadow = '0 5px 20px rgba(92, 184, 92, 0.5)';
                });
                
                playBtn.addEventListener('mouseleave', function() {
                    this.style.transform = 'scale(1)';
                    this.style.boxShadow = 'none';
                });
            }
        }
    }
    
    // End intro and transition to main content
    function endIntro() {
        const overlay = document.getElementById('videoIntroOverlay');
        const video = document.getElementById('introVideo');
        
        // Mark as seen
        markIntroAsSeen();
        
        // Fade out overlay
        overlay.classList.add('fade-out');
        
        // Pause video
        if (video) {
            video.pause();
        }
        
        // Remove body scroll lock
        document.body.classList.remove('intro-playing');
        
        // Remove overlay from DOM after fade completes
        setTimeout(() => {
            overlay.classList.add('hidden');
        }, 800);
    }
    
    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initVideoIntro);
    } else {
        initVideoIntro();
    }
    
    // Expose function to reset intro (useful for testing)
    window.resetIntro = function() {
        sessionStorage.removeItem(VIDEO_INTRO_KEY);
        localStorage.removeItem(VIDEO_INTRO_KEY);
        location.reload();
    };
    
})();