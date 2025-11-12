import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = context.read<AuthService>();
        await authService.logout();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successLogout),
              backgroundColor: AppTheme.successColor,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(currentUser),
          _buildDashboardTab(currentUser),
          _buildForumTab(),
          _buildProfileTab(currentUser),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Forum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            color: AppTheme.primaryLightColor,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'S',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppTheme.textOnPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: AppTheme.textOnPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currentUser?.fullName ?? 'Student',
                          style: TextStyle(
                            color: AppTheme.textOnPrimaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentUser?.studentId != null)
                          Text(
                            'ID: ${currentUser!.studentId}',
                            style: TextStyle(
                              color: AppTheme.textOnPrimaryColor.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // My Courses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Courses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semester selection coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Current Semester'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Placeholder for courses
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: AppTheme.textDisabledColor,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No courses enrolled yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Your instructor will enroll you in courses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textDisabledColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.assignment_turned_in,
                  title: 'Completed',
                  value: '0',
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_actions,
                  title: 'Pending',
                  value: '0',
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Upcoming',
                  value: '0',
                  color: AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  title: 'Avg Score',
                  value: '-',
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Upcoming Deadlines
          Text(
            'Upcoming Deadlines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Center(
                child: Text(
                  'No upcoming deadlines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum,
            size: 64,
            color: AppTheme.textDisabledColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Forum feature coming soon!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          // Profile Header
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'S',
              style: TextStyle(
                fontSize: 40,
                color: AppTheme.textOnPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            currentUser?.fullName ?? 'Student',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (currentUser?.studentId != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Student ID: ${currentUser!.studentId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingL),

          // Profile Info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(currentUser?.email ?? 'N/A'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Username'),
                  subtitle: Text(currentUser?.username ?? 'N/A'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Role'),
                  subtitle: Text(
                    currentUser?.role == AppConstants.roleStudent
                        ? 'Student'
                        : 'Instructor',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Actions
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
