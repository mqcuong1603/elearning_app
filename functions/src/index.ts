import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

// Initialize Firebase Admin
admin.initializeApp();

// Email configuration
// You'll need to set these in Firebase Functions config:
// firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
const gmailEmail = functions.config().gmail?.email;
const gmailPassword = functions.config().gmail?.password;

// Create nodemailer transporter
let transporter: nodemailer.Transporter | null = null;

if (gmailEmail && gmailPassword) {
  transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });
}

/**
 * Cloud Function triggered when a notification is created
 * Sends an email to the user
 */
export const sendNotificationEmail = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    try {
      const notification = snap.data();

      // Skip if no transporter configured
      if (!transporter) {
        console.warn("Email transporter not configured. Skipping email send.");
        return null;
      }

      // Get user data
      const userId = notification.userId;
      const userDoc = await admin.firestore().collection("users").doc(userId).get();

      if (!userDoc.exists) {
        console.error(`User not found: ${userId}`);
        return null;
      }

      const user = userDoc.data();
      const userEmail = user?.email;

      if (!userEmail) {
        console.error(`User ${userId} has no email address`);
        return null;
      }

      // Get notification type emoji
      const typeEmojis: { [key: string]: string } = {
        "announcement": "📢",
        "assignment": "📝",
        "quiz": "📊",
        "material": "📚",
        "message": "💬",
        "forum": "💭",
        "grade": "⭐",
        "deadline": "⏰",
      };

      const emoji = typeEmojis[notification.type] || "🔔";

      // Prepare email content
      const mailOptions = {
        from: `E-Learning App <${gmailEmail}>`,
        to: userEmail,
        subject: `${emoji} ${notification.title}`,
        html: generateEmailHTML(notification, user, emoji),
      };

      // Send email
      await transporter.sendMail(mailOptions);
      console.log(`Email sent to ${userEmail} for notification ${snap.id}`);

      return null;
    } catch (error) {
      console.error("Error sending notification email:", error);
      return null;
    }
  });

/**
 * Generate HTML email content
 */
function generateEmailHTML(
  notification: any,
  user: any,
  emoji: string
): string {
  const userName = user.fullName || user.username || "User";

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 30px;
          border-radius: 10px 10px 0 0;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 24px;
        }
        .emoji {
          font-size: 48px;
          margin-bottom: 10px;
        }
        .content {
          background: #ffffff;
          padding: 30px;
          border: 1px solid #e0e0e0;
          border-top: none;
        }
        .greeting {
          font-size: 16px;
          margin-bottom: 20px;
          color: #666;
        }
        .notification-title {
          font-size: 20px;
          font-weight: bold;
          color: #333;
          margin-bottom: 15px;
        }
        .notification-message {
          font-size: 16px;
          color: #555;
          margin-bottom: 20px;
          padding: 15px;
          background: #f5f5f5;
          border-left: 4px solid #667eea;
          border-radius: 4px;
        }
        .notification-type {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 5px 15px;
          border-radius: 20px;
          font-size: 14px;
          margin-bottom: 15px;
        }
        .footer {
          background: #f5f5f5;
          padding: 20px;
          border-radius: 0 0 10px 10px;
          text-align: center;
          font-size: 14px;
          color: #666;
        }
        .timestamp {
          font-size: 13px;
          color: #999;
          margin-top: 15px;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="emoji">${emoji}</div>
        <h1>New Notification</h1>
      </div>
      <div class="content">
        <div class="greeting">Hi ${userName},</div>
        <div class="notification-type">${notification.type.toUpperCase()}</div>
        <div class="notification-title">${notification.title}</div>
        <div class="notification-message">${notification.message}</div>
        <div class="timestamp">
          Received: ${new Date(notification.createdAt).toLocaleString()}
        </div>
      </div>
      <div class="footer">
        <p>This is an automated notification from your E-Learning App.</p>
        <p style="font-size: 12px; color: #999; margin-top: 10px;">
          Please do not reply to this email.
        </p>
      </div>
    </body>
    </html>
  `;
}
