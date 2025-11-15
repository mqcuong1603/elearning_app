import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';
import '../../widgets/user_avatar.dart';

class StudentDetailScreen extends StatelessWidget {
  final UserModel student;

  const StudentDetailScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Section
            UserAvatar(
              avatarUrl: student.avatarUrl,
              fallbackText: student.fullName,
              radius: 60,
              fontSize: 48,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              student.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '@${student.username}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Account Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildInfoRow(
                      context,
                      icon: Icons.badge,
                      label: 'Student ID',
                      value: student.studentId ?? 'N/A',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      value: student.email,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.account_circle,
                      label: 'Username',
                      value: student.username,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Joined',
                      value: DateFormat('MMM dd, yyyy').format(student.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Contact & Additional Information Card
            if (student.additionalInfo != null &&
                (student.additionalInfo!['phone'] != null &&
                        student.additionalInfo!['phone'].toString().isNotEmpty ||
                    student.additionalInfo!['address'] != null &&
                        student.additionalInfo!['address'].toString().isNotEmpty ||
                    student.additionalInfo!['bio'] != null &&
                        student.additionalInfo!['bio'].toString().isNotEmpty))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact & Additional Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Phone
                      if (student.additionalInfo!['phone'] != null &&
                          student.additionalInfo!['phone'].toString().isNotEmpty) ...[
                        _buildInfoRow(
                          context,
                          icon: Icons.phone,
                          label: 'Phone',
                          value: student.additionalInfo!['phone'],
                        ),
                        const Divider(),
                      ],

                      // Address
                      if (student.additionalInfo!['address'] != null &&
                          student.additionalInfo!['address'].toString().isNotEmpty) ...[
                        _buildInfoRow(
                          context,
                          icon: Icons.location_on,
                          label: 'Address',
                          value: student.additionalInfo!['address'],
                        ),
                        const Divider(),
                      ],

                      // Bio
                      if (student.additionalInfo!['bio'] != null &&
                          student.additionalInfo!['bio'].toString().isNotEmpty)
                        _buildInfoRow(
                          context,
                          icon: Icons.info,
                          label: 'Bio',
                          value: student.additionalInfo!['bio'],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
