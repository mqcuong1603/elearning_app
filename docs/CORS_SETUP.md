# Firebase Storage CORS Configuration Guide

## Problem
Avatar images uploaded to Firebase Storage return `HTTP request failed, statusCode: 0` errors when loading in the Flutter web app. This is due to CORS (Cross-Origin Resource Sharing) restrictions.

## Solution
Deploy the CORS configuration to Firebase Storage using Google Cloud SDK's `gsutil` command.

## Prerequisites

### 1. Install Google Cloud SDK
The Google Cloud SDK includes the `gsutil` command needed to configure CORS.

**macOS/Linux:**
```bash
# Download and install
curl https://sdk.cloud.google.com | bash

# Restart your shell
exec -l $SHELL

# Initialize gcloud
gcloud init
```

**Windows:**
Download the installer from: https://cloud.google.com/sdk/docs/install

### 2. Authenticate with Google Cloud
```bash
# Login to your Google account
gcloud auth login

# Set your project (if not already set)
gcloud config set project elearning-management-b4314
```

## Deployment Steps

### Option 1: Using the Deployment Script (Recommended)
```bash
# Run the deployment script
./deploy-cors.sh
```

### Option 2: Manual Deployment
```bash
# Deploy CORS configuration
gsutil cors set cors.json gs://elearning-management-b4314.firebasestorage.app

# Verify deployment
gsutil cors get gs://elearning-management-b4314.firebasestorage.app
```

## Verifying CORS Configuration

After deployment, you can verify the CORS settings:

```bash
gsutil cors get gs://elearning-management-b4314.firebasestorage.app
```

Expected output should show:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Content-Type",
      "Content-Length",
      "Content-Disposition",
      "Authorization",
      "User-Agent",
      "X-Requested-With",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Credentials"
    ]
  }
]
```

## Testing

After deploying CORS configuration:

1. **Clear browser cache** (important!)
   - Chrome: Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
   - Select "Cached images and files"
   - Clear data

2. **Hard reload the app**
   - Chrome: Ctrl+Shift+R (Cmd+Shift+R on Mac)

3. **Test avatar upload and display**
   - Navigate to profile page
   - Upload a new avatar
   - Avatar should display without errors

## Troubleshooting

### Error: "gsutil: command not found"
- Install Google Cloud SDK (see Prerequisites above)

### Error: "AccessDeniedException: 403"
- Ensure you're authenticated: `gcloud auth login`
- Verify project access: `gcloud projects list`
- Check you have Storage Admin role in Firebase Console

### Error: "BucketNotFoundException: 404"
- Verify bucket name is correct
- Check Firebase Storage is enabled in Firebase Console

### Images still fail to load after CORS deployment
1. Clear browser cache completely
2. Try incognito/private browsing mode
3. Check browser console for different error messages
4. Verify Storage Rules allow read access

## CORS Configuration Explained

```json
{
  "origin": ["*"],              // Allow requests from any origin
  "method": ["GET", "HEAD"],    // Allow GET and HEAD requests (for images)
  "maxAgeSeconds": 3600,        // Cache preflight for 1 hour
  "responseHeader": [...]       // Headers allowed in responses
}
```

### Security Note
The current configuration allows **all origins** (`"*"`). For production, consider restricting to specific domains:

```json
{
  "origin": ["https://yourdomain.com", "https://www.yourdomain.com"],
  ...
}
```

## Related Files
- `cors.json` - CORS configuration file
- `deploy-cors.sh` - Automated deployment script
- `storage.rules` - Firebase Storage security rules

## References
- [Firebase Storage CORS Configuration](https://firebase.google.com/docs/storage/web/download-files#cors_configuration)
- [Google Cloud Storage CORS](https://cloud.google.com/storage/docs/configuring-cors)
- [CORS Specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
