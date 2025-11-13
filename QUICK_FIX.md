# Quick Fix for Firestore Index Error

## The Problem
Error: `[cloud_firestore/failed-precondition] The query requires an index`

## Immediate Solution (Choose One)

### Option 1: Click the Link (Fastest)
1. Copy the URL from the error message
2. Open it in your browser
3. Click "Create Index"
4. Wait 1-2 minutes
5. Refresh your app

### Option 2: Deploy via Firebase CLI
```bash
firebase deploy --only firestore:indexes
```

### Option 3: Use the Fallback (Already Implemented)
The app now automatically falls back to sorting in memory if the index is missing. No action required!

## What Was Fixed

### 1. Created `firestore.indexes.json`
Defines the required composite index for querying groups by course.

### 2. Updated `GroupService`
Added smart fallback:
- First tries optimized query with orderBy
- If index missing, queries without orderBy
- Sorts results in memory
- App continues to work!

### 3. Updated `firebase.json`
Added Firestore configuration to reference the indexes file.

### 4. Created Documentation
- `FIRESTORE_SETUP.md` - Complete setup guide
- `QUICK_FIX.md` - This file

## Verification

Run the app and check:
- ✅ No more "failed-precondition" errors
- ✅ Groups load correctly in Course Space
- ✅ Students can see their group highlighted

## For Production

Before final deployment:
1. Deploy indexes: `firebase deploy --only firestore:indexes`
2. Verify in Firebase Console: Indexes → Status should be "Enabled"
3. Test with production data

## Need Help?

See `FIRESTORE_SETUP.md` for detailed instructions.

