# E-Learning App Cloud Functions

This directory contains Firebase Cloud Functions for the E-Learning Management System.

## 📦 Functions

### `sendNotificationEmail`

Automatically sends email notifications to users when notifications are created in Firestore.

**Trigger:** Firestore document creation in `notifications/{notificationId}`

**What it does:**
1. Listens for new notifications in Firestore
2. Fetches the user's email from the users collection
3. Sends a formatted HTML email using Nodemailer
4. Logs the result

## 🏗️ Project Structure

```
functions/
├── src/
│   └── index.ts          # Main Cloud Functions code
├── lib/                  # Compiled JavaScript (generated)
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
├── .eslintrc.js          # ESLint configuration
├── .env.example          # Environment variables template
└── README.md            # This file
```

## 🚀 Quick Start

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment variables:**
   ```bash
   firebase functions:config:set gmail.email="your-email@gmail.com"
   firebase functions:config:set gmail.password="your-app-password"
   ```

3. **Build the functions:**
   ```bash
   npm run build
   ```

4. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```

## 🛠️ Available Scripts

- `npm run lint` - Run ESLint
- `npm run build` - Compile TypeScript to JavaScript
- `npm run build:watch` - Watch mode for development
- `npm run serve` - Start Firebase emulator
- `npm run deploy` - Deploy to Firebase
- `npm run logs` - View function logs

## 📧 Email Configuration

The function uses **Nodemailer** with **Gmail**. You need:

1. Gmail account with 2-Factor Authentication
2. App Password generated from Google Account settings
3. Environment variables set via Firebase CLI

See `CLOUD_FUNCTIONS_SETUP.md` in the project root for detailed setup instructions.

## 🧪 Testing

### Local Testing

```bash
# Get production config for local testing
firebase functions:config:get > .runtimeconfig.json

# Start emulator
npm run serve
```

### View Logs

```bash
# View all logs
npm run logs

# Or use Firebase CLI
firebase functions:log --only sendNotificationEmail
```

## 🔄 Development Workflow

1. Make changes to `src/index.ts`
2. Build: `npm run build`
3. Test locally with emulator (optional)
4. Deploy: `npm run deploy`
5. Monitor: `npm run logs`

## 📝 Adding New Functions

To add a new Cloud Function:

1. Export a new function in `src/index.ts`:
   ```typescript
   export const myNewFunction = functions.firestore
     .document('collection/{docId}')
     .onCreate(async (snap, context) => {
       // Your code here
     });
   ```

2. Build and deploy:
   ```bash
   npm run build
   firebase deploy --only functions:myNewFunction
   ```

## 🐛 Debugging

1. **Check logs:**
   ```bash
   firebase functions:log
   ```

2. **Check config:**
   ```bash
   firebase functions:config:get
   ```

3. **Check Firebase Console:**
   - Go to Firebase Console → Functions
   - View execution logs, errors, and metrics

## 📚 Dependencies

- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- `nodemailer` - Email sending library

## ⚙️ TypeScript Configuration

The project uses TypeScript with strict mode enabled. Configuration is in `tsconfig.json`.

## 🔐 Security Notes

- Never commit `.runtimeconfig.json` (contains secrets)
- Never commit `node_modules/`
- Use app passwords, not real Gmail passwords
- Environment variables are stored in Firebase (not in code)

## 📖 Learn More

- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

For detailed setup instructions, see `CLOUD_FUNCTIONS_SETUP.md` in the project root.
