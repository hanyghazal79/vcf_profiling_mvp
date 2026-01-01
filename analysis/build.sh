#!/bin/bash
# [file name]: build.sh
# [file content begin]
#!/bin/bash

echo "Starting build process..."

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Create necessary directories
mkdir -p tmp/vcf_uploads tmp/vcf_direct tmp/test_vcf tmp/results reports

echo "Build completed successfully!"
# [file content end]