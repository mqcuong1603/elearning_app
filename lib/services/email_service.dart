import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/app_constants.dart';

/// Service for sending email notifications
/// Configurable SMTP settings for sending emails to students
class EmailService {
  // SMTP Configuration - To be set by the application
  String? _smtpHost;
  int? _smtpPort;
  String? _senderEmail;
  String? _senderPassword;
  String? _senderName;
  bool _isConfigured = false;

  EmailService();

  /// Configure SMTP settings
  void configureSMTP({
    required String smtpHost,
    required int smtpPort,
    required String senderEmail,
    required String senderPassword,
    String? senderName,
  }) {
    _smtpHost = smtpHost;
    _smtpPort = smtpPort;
    _senderEmail = senderEmail;
    _senderPassword = senderPassword;
    _senderName = senderName ?? 'E-Learning System';
    _isConfigured = true;
    print('Email service configured successfully');
  }

  /// Check if email service is configured
  bool get isConfigured => _isConfigured;

  // ==================== SEND EMAIL ====================

  /// Send a generic email
  Future<bool> sendEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    bool isHtml = true,
  }) async {
    if (!_isConfigured) {
      print('Email service not configured. Skipping email send.');
      return false;
    }

    try {
      final smtpServer = SmtpServer(
        _smtpHost!,
        port: _smtpPort!,
        username: _senderEmail,
        password: _senderPassword,
        ignoreBadCertificate: false,
        ssl: _smtpPort == 465,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_senderEmail!, _senderName!)
        ..recipients.add(recipientEmail)
        ..subject = subject;

      if (isHtml) {
        message.html = body;
      } else {
        message.text = body;
      }

      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  /// Send email asynchronously (non-blocking)
  Future<void> sendEmailAsync({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    bool isHtml = true,
  }) async {
    // Fire and forget - don't wait for the result
    sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: isHtml,
    ).catchError((error) {
      print('Async email error: $error');
    });
  }

  // ==================== NOTIFICATION EMAILS ====================

  /// Send email for new announcement
  Future<bool> sendAnnouncementEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String announcementTitle,
    required String announcementContent,
  }) async {
    final subject = '[$courseName] New Announcement: $announcementTitle';
    final body = _buildAnnouncementEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      announcementTitle: announcementTitle,
      announcementContent: announcementContent,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Send email for approaching assignment deadline
  Future<bool> sendAssignmentDeadlineEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String assignmentTitle,
    required DateTime deadline,
    required int hoursRemaining,
  }) async {
    final subject = '⏰ [$courseName] Assignment Deadline Approaching: $assignmentTitle';
    final body = _buildDeadlineEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      itemType: 'Assignment',
      itemTitle: assignmentTitle,
      deadline: deadline,
      hoursRemaining: hoursRemaining,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Send email for approaching quiz deadline
  Future<bool> sendQuizDeadlineEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String quizTitle,
    required DateTime deadline,
    required int hoursRemaining,
  }) async {
    final subject = '⏰ [$courseName] Quiz Deadline Approaching: $quizTitle';
    final body = _buildDeadlineEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      itemType: 'Quiz',
      itemTitle: quizTitle,
      deadline: deadline,
      hoursRemaining: hoursRemaining,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Send email for assignment submission confirmation
  Future<bool> sendAssignmentSubmissionConfirmationEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String assignmentTitle,
    required DateTime submissionTime,
  }) async {
    final subject = '✅ [$courseName] Assignment Submitted: $assignmentTitle';
    final body = _buildSubmissionConfirmationEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      itemType: 'Assignment',
      itemTitle: assignmentTitle,
      submissionTime: submissionTime,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Send email for quiz submission confirmation
  Future<bool> sendQuizSubmissionConfirmationEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String quizTitle,
    required DateTime submissionTime,
    double? score,
  }) async {
    final subject = '✅ [$courseName] Quiz Submitted: $quizTitle';
    final body = _buildQuizSubmissionConfirmationEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      quizTitle: quizTitle,
      submissionTime: submissionTime,
      score: score,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Send email for important feedback (grading)
  Future<bool> sendFeedbackEmail({
    required String recipientEmail,
    required String recipientName,
    required String courseName,
    required String assignmentTitle,
    required double grade,
    String? feedback,
  }) async {
    final subject = '⭐ [$courseName] You received feedback on: $assignmentTitle';
    final body = _buildFeedbackEmailBody(
      recipientName: recipientName,
      courseName: courseName,
      assignmentTitle: assignmentTitle,
      grade: grade,
      feedback: feedback,
    );

    return await sendEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  // ==================== EMAIL TEMPLATES ====================

  String _buildAnnouncementEmailBody({
    required String recipientName,
    required String courseName,
    required String announcementTitle,
    required String announcementContent,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1976D2; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .footer { margin-top: 20px; text-align: center; font-size: 12px; color: #777; }
    .announcement-content { background-color: white; padding: 15px; margin-top: 15px; border-left: 4px solid #1976D2; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>📢 New Announcement</h2>
    </div>
    <div class="content">
      <p>Hi <strong>$recipientName</strong>,</p>
      <p>A new announcement has been posted in <strong>$courseName</strong>:</p>
      <h3>$announcementTitle</h3>
      <div class="announcement-content">
        $announcementContent
      </div>
      <p style="margin-top: 20px;">Log in to the E-Learning System to view details and participate in the discussion.</p>
    </div>
    <div class="footer">
      <p>This is an automated email from E-Learning Management System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildDeadlineEmailBody({
    required String recipientName,
    required String courseName,
    required String itemType,
    required String itemTitle,
    required DateTime deadline,
    required int hoursRemaining,
  }) {
    final deadlineStr = deadline.toString().split('.')[0]; // Remove microseconds
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #FF6F00; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .warning { background-color: #FFF3E0; padding: 15px; margin: 15px 0; border-left: 4px solid #FF6F00; }
    .footer { margin-top: 20px; text-align: center; font-size: 12px; color: #777; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>⏰ Deadline Approaching</h2>
    </div>
    <div class="content">
      <p>Hi <strong>$recipientName</strong>,</p>
      <p>This is a reminder that the deadline for the following $itemType is approaching:</p>
      <div class="warning">
        <h3>$itemTitle</h3>
        <p><strong>Course:</strong> $courseName</p>
        <p><strong>Deadline:</strong> $deadlineStr</p>
        <p><strong>Time Remaining:</strong> $hoursRemaining hours</p>
      </div>
      <p>Please make sure to complete and submit your work before the deadline.</p>
    </div>
    <div class="footer">
      <p>This is an automated email from E-Learning Management System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildSubmissionConfirmationEmailBody({
    required String recipientName,
    required String courseName,
    required String itemType,
    required String itemTitle,
    required DateTime submissionTime,
  }) {
    final submissionStr = submissionTime.toString().split('.')[0];
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .success { background-color: #E8F5E9; padding: 15px; margin: 15px 0; border-left: 4px solid #4CAF50; }
    .footer { margin-top: 20px; text-align: center; font-size: 12px; color: #777; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>✅ Submission Confirmed</h2>
    </div>
    <div class="content">
      <p>Hi <strong>$recipientName</strong>,</p>
      <p>Your $itemType submission has been received successfully!</p>
      <div class="success">
        <h3>$itemTitle</h3>
        <p><strong>Course:</strong> $courseName</p>
        <p><strong>Submitted at:</strong> $submissionStr</p>
      </div>
      <p>Your instructor will review your submission and provide feedback soon.</p>
    </div>
    <div class="footer">
      <p>This is an automated email from E-Learning Management System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildQuizSubmissionConfirmationEmailBody({
    required String recipientName,
    required String courseName,
    required String quizTitle,
    required DateTime submissionTime,
    double? score,
  }) {
    final submissionStr = submissionTime.toString().split('.')[0];
    final scoreDisplay = score != null ? '<p><strong>Score:</strong> ${score.toStringAsFixed(1)}</p>' : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .success { background-color: #E8F5E9; padding: 15px; margin: 15px 0; border-left: 4px solid #4CAF50; }
    .footer { margin-top: 20px; text-align: center; font-size: 12px; color: #777; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>✅ Quiz Submitted</h2>
    </div>
    <div class="content">
      <p>Hi <strong>$recipientName</strong>,</p>
      <p>Your quiz has been submitted successfully!</p>
      <div class="success">
        <h3>$quizTitle</h3>
        <p><strong>Course:</strong> $courseName</p>
        <p><strong>Submitted at:</strong> $submissionStr</p>
        $scoreDisplay
      </div>
      <p>Log in to the E-Learning System to view detailed results.</p>
    </div>
    <div class="footer">
      <p>This is an automated email from E-Learning Management System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  String _buildFeedbackEmailBody({
    required String recipientName,
    required String courseName,
    required String assignmentTitle,
    required double grade,
    String? feedback,
  }) {
    final feedbackSection = feedback != null && feedback.isNotEmpty
        ? '<div style="background-color: white; padding: 15px; margin-top: 15px; border-left: 4px solid #1976D2;"><strong>Feedback:</strong><p>$feedback</p></div>'
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #7B1FA2; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; margin-top: 20px; border-radius: 5px; }
    .grade-box { background-color: #E1BEE7; padding: 15px; margin: 15px 0; text-align: center; border-radius: 5px; }
    .footer { margin-top: 20px; text-align: center; font-size: 12px; color: #777; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>⭐ New Feedback Received</h2>
    </div>
    <div class="content">
      <p>Hi <strong>$recipientName</strong>,</p>
      <p>Your instructor has graded your assignment:</p>
      <h3>$assignmentTitle</h3>
      <p><strong>Course:</strong> $courseName</p>
      <div class="grade-box">
        <h2 style="margin: 0; color: #7B1FA2;">Grade: ${grade.toStringAsFixed(1)}</h2>
      </div>
      $feedbackSection
      <p style="margin-top: 20px;">Log in to the E-Learning System to view full details.</p>
    </div>
    <div class="footer">
      <p>This is an automated email from E-Learning Management System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
