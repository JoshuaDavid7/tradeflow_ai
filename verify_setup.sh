#!/bin/bash
# TradeFlow AI - Setup Verification Script

echo "🚀 TradeFlow AI - Setup Verification"
echo "===================================="
echo ""

# Colors
GREEN='\033[0.32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Flutter installed
echo -n "✓ Checking Flutter... "
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED - Flutter not found${NC}"
    exit 1
fi

# Check 2: Dependencies installed
echo -n "✓ Checking dependencies... "
if [ -d ".dart_tool" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Run: flutter pub get${NC}"
fi

# Check 3: Generated files exist
echo -n "✓ Checking generated files... "
if [ -f "lib/data/local/database.g.dart" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${YELLOW}Run: flutter pub run build_runner build --delete-conflicting-outputs${NC}"
    exit 1
fi

# Check 4: Environment files
echo -n "✓ Checking .env files... "
if [ -f ".env.development" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Create .env.development from .env.example${NC}"
fi

# Check 5: Asset directories
echo -n "✓ Checking asset directories... "
if [ -d "assets/animations" ] && [ -d "assets/images" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Creating asset directories...${NC}"
    mkdir -p assets/animations assets/images
fi

echo ""
echo "🎯 Running flutter analyze..."
echo "============================="
flutter analyze

echo ""
echo "✅ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Configure .env.development with your Supabase credentials"
echo "2. Create Supabase tables (see README_PRODUCTION.md)"
echo "3. Run: flutter run --dart-define=ENV=development"
