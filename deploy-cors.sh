#!/bin/bash

# Deploy CORS Configuration to Firebase Storage
# This script requires Google Cloud SDK (gcloud) with gsutil

BUCKET="gs://elearning-management-b4314.firebasestorage.app"
CORS_FILE="cors.json"

echo "🔧 Deploying CORS configuration to Firebase Storage..."
echo "Bucket: $BUCKET"
echo ""

# Check if gsutil is installed
if ! command -v gsutil &> /dev/null; then
    echo "❌ Error: gsutil is not installed"
    echo ""
    echo "To install Google Cloud SDK (includes gsutil):"
    echo "1. Visit: https://cloud.google.com/sdk/docs/install"
    echo "2. Follow installation instructions for your platform"
    echo "3. Run: gcloud init"
    echo "4. Authenticate with your Google account"
    echo ""
    exit 1
fi

# Check if CORS file exists
if [ ! -f "$CORS_FILE" ]; then
    echo "❌ Error: $CORS_FILE not found"
    exit 1
fi

# Deploy CORS configuration
echo "📤 Deploying CORS configuration..."
gsutil cors set "$CORS_FILE" "$BUCKET"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CORS configuration deployed successfully!"
    echo ""
    echo "📋 Verifying CORS configuration..."
    gsutil cors get "$BUCKET"
else
    echo ""
    echo "❌ Failed to deploy CORS configuration"
    echo "Make sure you're authenticated with: gcloud auth login"
    exit 1
fi
