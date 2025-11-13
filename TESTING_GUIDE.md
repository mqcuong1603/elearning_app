# E-Learning Management App - Testing Guide

## ✅ What's Been Implemented (Ready to Test)

### 1. **Core Services**
- ✅ **AuthService** - Authentication with admin/admin login
- ✅ **FirestoreService** - CRUD operations for Firebase
- ✅ **HiveService** - Offline caching
- ✅ **StorageService** - File uploads to Firebase Storage

### 2. **Authentication Flow**
- ✅ Splash screen with session validation
- ✅ Login screen with form validation
- ✅ Instructor dashboard (admin/admin)
- ✅ Student home screen (4 tabs)
- ✅ Logout functionality

---

## 🚀 How to Test Locally

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run the App
Choose your platform:

**For Android:**
```bash
flutter run -d android
```

**For Windows:**
```bash
flutter run -d windows
```

**For Web:**
```bash
flutter run -d chrome
```

### Step 3: Test Authentication

#### Test as Instructor (Admin)
1. Open the app
2. You'll see the login screen with test credentials displayed
3. Enter:
   - Username: `admin`
   - Password: `admin`
4. Click **Login**
5. You should be redirected to the **Instructor Dashboard**
6. Verify you can see:
   - Welcome card with "Administrator" name
   - Quick stats (0 courses, 0 students, etc.)
   - Quick action cards (Semesters, Courses, Students, Groups)
7. Click **Logout** icon in the app bar
8. Confirm logout dialog
9. You should be redirected back to the login screen

#### Test as Student (Will Fail for Now - Expected)
1. Try logging in with any other username/password
2. You should see an error: "Invalid username or password"
3. This is expected because students need to be created by the instructor first

---

## 📱 What You Should See

### Login Screen
- App logo (school icon)
- "E-Learning Management" title
- Username and password fields
- Login button
- Info card showing test credentials (admin/admin)

### Instructor Dashboard
- App bar with title "Instructor Dashboard"
- Notifications icon (shows "coming soon" message)
- Logout icon
- Welcome card with avatar and name
- 4 stat cards showing:
  - Courses: 0
  - Students: 0
  - Assignments: 0
  - Quizzes: 0
- 4 quick action cards (all show "coming soon" messages):
  - Manage Semesters
  - Manage Courses
  - Manage Students
  - Manage Groups

### Student Home Screen (After Student Feature is Built)
- Bottom navigation with 4 tabs:
  - **Home**: Shows enrolled courses
  - **Dashboard**: Progress stats
  - **Forum**: Forum discussions
  - **Profile**: User profile info
- All features will show placeholders until implemented

---

## 🐛 Common Issues and Solutions

### Issue: "Firebase initialization failed"
**Solution:** Make sure you ran `flutter pub get` to install Firebase dependencies.

### Issue: "Hive initialization error"
**Solution:** This might happen on first run. Restart the app and it should work.

### Issue: App shows blank white screen
**Solution:**
1. Check the terminal for error messages
2. Make sure you're using Flutter SDK 3.0.0 or higher
3. Run `flutter clean` then `flutter pub get`

### Issue: "Invalid username or password" for admin/admin
**Solution:**
1. Make sure you typed exactly: `admin` and `admin` (lowercase)
2. Check that there are no spaces before or after

### Issue: Build errors about missing files
**Solution:** The app references some files that will be generated later:
- Hive adapters (*.g.dart files) will be generated when you run build_runner
- For now, the app will work without them
- The HiveService has commented out adapter registrations

---

## 🔧 Next Features to Build

### Priority 1: Semester Management
- [ ] List all semesters
- [ ] Create new semester
- [ ] Edit semester
- [ ] Delete semester
- [ ] Mark semester as current
- [ ] CSV import/export with preview

### Priority 2: Course Management
- [ ] List courses by semester
- [ ] Create new course
- [ ] Edit course (name, code, sessions, cover image)
- [ ] Delete course
- [ ] CSV import/export with preview

### Priority 3: Student Management
- [ ] List all students
- [ ] Create new student account
- [ ] Edit student info
- [ ] Delete student
- [ ] CSV import/export with preview
- [ ] Batch import with validation

### Priority 4: Group Management
- [ ] Create groups for courses
- [ ] Assign students to groups
- [ ] View group members
- [ ] CSV import/export

---

## 📝 Testing Checklist

Use this checklist when testing:

- [ ] App launches without errors
- [ ] Splash screen shows for 2 seconds
- [ ] Login screen appears after splash
- [ ] Can see admin credentials info card
- [ ] Username field validation works (required)
- [ ] Password field validation works (required)
- [ ] Password visibility toggle works
- [ ] Login with admin/admin succeeds
- [ ] Success message shows after login
- [ ] Redirects to Instructor Dashboard
- [ ] Dashboard shows correct user name (Administrator)
- [ ] Stats cards display (all showing 0)
- [ ] Quick action cards are clickable
- [ ] Clicking action cards shows "coming soon" message
- [ ] Notifications icon works
- [ ] Logout icon shows confirmation dialog
- [ ] Logout succeeds and redirects to login
- [ ] Login with wrong credentials shows error
- [ ] Error message is user-friendly

---

## 💡 Tips for Testing

1. **Use Hot Reload**: After making changes, press `r` in the terminal to hot reload
2. **Use Hot Restart**: Press `R` for full app restart if hot reload doesn't work
3. **Check Logs**: Look at terminal output for any errors or warnings
4. **Test Different Screen Sizes**: Try resizing the window (for desktop/web) to test responsiveness
5. **Test Offline**: Turn off WiFi to see how the app handles no internet (will fail gracefully for now)

---

## 📞 Need Help?

If you encounter any issues:
1. Check the error message in the terminal
2. Make sure all dependencies are installed (`flutter pub get`)
3. Try `flutter clean` and rebuild
4. Check that Firebase configuration is correct in `lib/config/firebase_options.dart`

---

## ✨ What's Working vs. What's Coming

### ✅ Working Now
- Firebase initialization
- Hive initialization
- Login/logout
- Session persistence
- Role-based routing
- Basic UI with Material Design 3

### 🚧 Coming Next
- Semester CRUD operations
- Course CRUD operations
- Student CRUD operations
- Group CRUD operations
- CSV import/export with preview
- Content distribution (Announcements, Assignments, Quizzes, Materials)
- Forums and messaging
- Notifications
- Offline mode sync
- And much more!

---

**Happy Testing!** 🎉

Test the authentication flow and let me know if everything works as expected. Once confirmed, I'll continue building the management features.
