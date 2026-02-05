#!/bin/bash

set -e

STATIC_DIR="."
RESPONSIVE_CSS="${STATIC_DIR}/responsive-mobile.css"

echo "======================================"
echo "News Card Spacing Auto-Fix"
echo "======================================"
echo ""

if [ ! -f "$RESPONSIVE_CSS" ]; then
    echo "ERROR: responsive-mobile.css not found!"
    echo "Please make sure you're in the static directory."
    exit 1
fi

echo "[1/2] Creating backup..."
cp "$RESPONSIVE_CSS" "${RESPONSIVE_CSS}.spacing-backup.$(date +%Y%m%d_%H%M%S)"
echo "✓ Backup created"
echo ""

echo "[2/2] Adding spacing fix..."

if grep -q "padding-left: 30px !important" "$RESPONSIVE_CSS"; then
    echo "⚠ Fix already applied, skipping..."
else
    cat >> "$RESPONSIVE_CSS" << 'EOFCSS'

.news-card {
    padding-left: 30px !important;
}

.news-header,
.news-title,
.news-description,
.news-footer {
    margin-left: 0 !important;
}

@media (max-width: 768px) {
    .news-card {
        padding-left: 25px !important;
    }
}

@media (max-width: 480px) {
    .news-card {
        padding-left: 22px !important;
    }
}
EOFCSS
    echo "✓ Spacing fix added"
fi

echo ""
echo "======================================"
echo "✓ Fix Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Hard refresh browser: Ctrl+Shift+R"
echo "  2. Check news cards - text should not touch green border"
echo ""