#!/bin/bash
# Complete deployment setup script

echo "🚀 BREAST CANCER APP DEPLOYMENT SETUP"
echo "======================================"
echo ""

# Create deployment configurations
create_configs() {
    echo "📝 Creating deployment configuration files..."
    
    # 1. Create vercel.json for Frontend
    cat > vercel.json << 'EOF'
{
  "version": 2,
  "name": "breast-cancer-genetics-app",
  "builds": [
    {
      "src": "ui/build/web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*\\.(js|css|jpg|jpeg|png|gif|svg|woff|woff2|ttf|eot|ico|json))",
      "headers": {
        "cache-control": "public, max-age=31536000, immutable"
      },
      "dest": "/ui/build/web/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/ui/build/web/index.html"
    }
  ]
}
EOF
    
    # 2. Create render.yaml for Backend
    cat > render.yaml << 'EOF'
services:
  - type: web
    name: breast-cancer-api
    env: python
    region: oregon
    plan: free
    branch: main
    buildCommand: |
      cd analysis
      pip install --upgrade pip
      pip install -r requirements.txt
    startCommand: cd analysis && uvicorn api_server:app --host 0.0.0.0 --port $PORT
    healthCheckPath: /api/health
    envVars:
      - key: PYTHON_VERSION
        value: 3.11.0
      - key: PORT
        value: 8000
EOF
    
    # 3. Create .gitignore if not exists
    cat > .gitignore << 'EOF'
# Flutter
ui/build/
ui/.dart_tool/
ui/.flutter-plugins
ui/.flutter-plugins-dependencies
ui/.packages
ui/pubspec.lock

# Python
analysis/__pycache__/
analysis/*.pyc
analysis/*.pyo
analysis/*.pyd
analysis/.Python
analysis/env/
analysis/venv/
analysis/*.egg-info/
analysis/dist/
analysis/build/
analysis/*.so
analysis/*.json
analysis/*.pdf
analysis/*.vcf
analysis/reports/
analysis/test_*.vcf

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*

# Environment
.env
.env.local
EOF
    
    # 4. Create GitHub Actions workflow (optional)
    mkdir -p .github/workflows
    cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          
      - name: Build Flutter Web
        run: |
          cd ui
          flutter pub get
          flutter build web --release
          
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./ui/build/web
          vercel-args: '--prod'
EOF
    
    # 5. Update requirements.txt with complete dependencies
    cat > analysis/requirements.txt << 'EOF'
# Core Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6

# Data Processing
pandas==2.1.3
numpy==1.26.2

# Visualization
matplotlib==3.8.2
seaborn==0.13.0

# PDF Generation
reportlab==4.0.7

# Async Support
aiofiles==23.2.1

# Data Validation
pydantic==2.5.0

# HTTP Client (optional)
httpx==0.25.2

# Optional: VCF parsing (if needed)
# cyvcf2==0.30.28
EOF
    
    # 6. Create deployment README
    cat > DEPLOYMENT.md << 'EOF'
# Deployment Guide

## Quick Start

### 1. Deploy Backend (Render)
1. Push code to GitHub
2. Go to https://render.com
3. New Web Service → Connect your repo
4. Use settings from `render.yaml`
5. Deploy (takes ~5 min)
6. Copy your API URL: `https://YOUR-APP.onrender.com`

### 2. Update Flutter App
Edit `ui/lib/analysis_page.dart`:
```dart
String _apiUrl = 'https://YOUR-APP.onrender.com';
```

### 3. Deploy Frontend (Vercel)
```bash
cd ui
flutter build web --release
cd ..
vercel --prod
```

## Your Live URLs
- **Frontend:** https://your-app.vercel.app
- **Backend:** https://your-app.onrender.com
- **API Docs:** https://your-app.onrender.com/api/docs

## Monitoring
- Render Dashboard: https://dashboard.render.com
- Vercel Dashboard: https://vercel.com/dashboard

## Cost: $0/month (Free Tier)
EOF
    
    echo "✅ Configuration files created!"
}

# Build Flutter web
build_flutter() {
    echo ""
    echo "🔨 Building Flutter Web..."
    cd ui
    flutter clean
    flutter pub get
    flutter build web --release --web-renderer html
    cd ..
    echo "✅ Flutter build complete!"
}

# Main execution
main() {
    echo "Starting deployment setup..."
    echo ""
    
    create_configs
    
    read -p "Build Flutter web now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_flutter
    fi
    
    echo ""
    echo "🎉 Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "1. Push to GitHub: git add . && git commit -m 'Deploy setup' && git push"
    echo "2. Deploy backend to Render (see DEPLOYMENT.md)"
    echo "3. Update API URL in Flutter app"
    echo "4. Deploy frontend: vercel --prod"
    echo ""
    echo "📚 Read DEPLOYMENT.md for detailed instructions"
}

main
