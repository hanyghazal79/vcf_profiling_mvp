#!/bin/bash
# sync_to_pythonanywhere.sh

PYTHONANYWHERE_USER="hanyghazal79"
PROJECT_DIR="/path/to/your/local/project"
REMOTE_DIR="/home/hanyghazal79/breast-cancer-analysis"

# Sync all files
rsync -avz --progress \
    --exclude '.git/' \
    --exclude '__pycache__/' \
    --exclude '*.pyc' \
    --exclude '.env' \
    --exclude 'venv/' \
    "${PROJECT_DIR}/" \
    "${PYTHONANYWHERE_USER}@ssh.pythonanywhere.com:${REMOTE_DIR}/"

# SSH and restart
ssh "${PYTHONANYWHERE_USER}@ssh.pythonanywhere.com" << 'EOF'
    cd ~/breast-cancer-analysis
    
    # Set permissions
    chmod +x *.py
    
    # Create necessary directories
    mkdir -p /tmp/vcf_uploads
    mkdir -p /tmp/results
    mkdir -p ~/tmp/vcf_uploads
    mkdir -p ~/tmp/vcf_direct
    mkdir -p ~/tmp/test_vcf
    
    # Install dependencies
    pip install fastapi uvicorn python-multipart reportlab matplotlib seaborn pandas --user
    
    # Restart web app
    touch /var/www/hanyghazal79_pythonanywhere_com_wsgi.py
    
    echo "Files synced and app restarted!"
EOF