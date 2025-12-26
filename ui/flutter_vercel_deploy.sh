#!/bin/bash
# Step-by-step Flutter Web deployment to Vercel

echo "=== FLUTTER WEB DEPLOYMENT TO VERCEL ==="
echo ""

# Step 1: Build Flutter Web
echo "Step 1: Building Flutter Web..."
cd ui
flutter clean
flutter pub get
flutter build web --release --web-renderer html
cd ..

# Step 2: Create vercel.json configuration
echo "Step 2: Creating Vercel configuration..."
cat > vercel.json << 'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "ui/build/web/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/ui/build/web/$1"
    }
  ],
  "outputDirectory": "ui/build/web"
}
EOF

# Step 3: Install Vercel CLI (if not installed)
echo "Step 3: Installing Vercel CLI..."
npm install -g vercel

# Step 4: Deploy to Vercel
echo "Step 4: Deploying to Vercel..."
echo "You'll be prompted to:"
echo "  1. Login to Vercel (if first time)"
echo "  2. Link to your project"
echo "  3. Confirm settings"
echo ""
vercel --prod

echo ""
echo "✅ Deployment complete!"
echo "Your Flutter app is now live on Vercel!"
