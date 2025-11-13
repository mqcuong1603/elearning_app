# Firestore Setup Guide

## Issue: Missing Composite Index

When querying groups by course with ordering, Firestore requires a composite index. This document explains how to set up the required indexes.

## Quick Fix (Automatic)

1. Click the URL provided in the error message to automatically create the index in Firebase Console
2. Wait 1-2 minutes for the index to build
3. Refresh your app

## Manual Setup via Firebase CLI

### Prerequisites
- Install Firebase CLI: `npm install -g firebase-tools`
- Login: `firebase login`
- Initialize: `firebase init firestore` (if not already initialized)

### Deploy Indexes

```bash
firebase deploy --only firestore:indexes
```

This will deploy the indexes defined in `firestore.indexes.json`.

## Manual Setup via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `elearning-management-b4314`
3. Navigate to: Firestore Database → Indexes
4. Click "Create Index"
5. Configure the index:
   - **Collection ID**: `groups`
   - **Fields to index**:
     - `courseId` - Ascending
     - `name` - Ascending
   - **Query scope**: Collection
6. Click "Create"
7. Wait for the index to build (usually 1-2 minutes)

## Fallback Mechanism

The app includes a fallback mechanism that:
1. First attempts the optimized query with `orderBy`
2. If the index is missing, catches the error
3. Falls back to querying without `orderBy`
4. Sorts results in memory

This ensures the app continues to work even if indexes haven't been deployed yet.

## Index Configuration

The `firestore.indexes.json` file contains:

```json
{
  "indexes": [
    {
      "collectionGroup": "groups",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "courseId", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Verification

After deploying indexes, verify by:
1. Checking Firebase Console → Firestore Database → Indexes
2. Status should show "Enabled" (not "Building")
3. Test the app - no more index errors should appear

## Troubleshooting

### Index still building
- Wait a few more minutes
- Check Firebase Console for index status
- For small datasets, builds usually take < 2 minutes

### Error persists after deploying
- Verify you deployed to the correct project
- Check `firebase use` to see active project
- Clear app cache and restart

### Multiple index errors
- Check console logs for all missing indexes
- Click each URL to create indexes
- Or add all to `firestore.indexes.json` and deploy

## Production Deployment Checklist

Before deploying to production:
- [ ] All indexes deployed and enabled
- [ ] Indexes tested with production-like data volume
- [ ] Security rules configured
- [ ] Backup strategy in place
- [ ] Monitoring and alerts configured

