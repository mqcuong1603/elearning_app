// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../config/app_theme.dart';
// import '../../config/app_constants.dart';
// import '../../services/auth_service.dart';
// import '../instructor/instructor_dashboard_screen.dart';
// import '../student/student_home_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogin() async {
//     // Clear previous error
//     setState(() {
//       _errorMessage = null;
//     });

//     // Validate form
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final authService = context.read<AuthService>();

//       // Attempt login
//       final user = await authService.login(
//         _usernameController.text.trim(),
//         _passwordController.text,
//       );

//       if (!mounted) return;

//       if (user != null) {
//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(AppConstants.successLogin),
//             backgroundColor: AppTheme.successColor,
//           ),
//         );

//         // Navigate to appropriate screen based on role
//         if (user.isInstructor) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (_) => const InstructorDashboardScreen(),
//             ),
//           );
//         } else {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (_) => const StudentHomeScreen(),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString().replaceAll('Exception: ', '');
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(AppTheme.spacingL),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // App Logo/Icon
//                 Icon(
//                   Icons.school,
//                   size: 80,
//                   color: AppTheme.primaryColor,
//                 ),
//                 const SizedBox(height: AppTheme.spacingL),

//                 // App Title
//                 Text(
//                   'E-Learning Management',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         color: AppTheme.primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: AppTheme.spacingS),
//                 Text(
//                   'Faculty of Information Technology',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppTheme.textSecondaryColor,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: AppTheme.spacingXL),

//                 // Login Card
//                 Card(
//                   elevation: AppTheme.elevationM,
//                   child: Padding(
//                     padding: const EdgeInsets.all(AppTheme.spacingL),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           // Title
//                           Text(
//                             'Login',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineSmall
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: AppTheme.spacingL),

//                           // Username Field
//                           TextFormField(
//                             controller: _usernameController,
//                             decoration: const InputDecoration(
//                               labelText: 'Username',
//                               prefixIcon: Icon(Icons.person),
//                               hintText: 'Enter your username',
//                             ),
//                             textInputAction: TextInputAction.next,
//                             enabled: !_isLoading,
//                             validator: (value) {
//                               if (value == null || value.trim().isEmpty) {
//                                 return AppConstants.validationRequired;
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: AppTheme.spacingM),

//                           // Password Field
//                           TextFormField(
//                             controller: _passwordController,
//                             obscureText: _obscurePassword,
//                             decoration: InputDecoration(
//                               labelText: 'Password',
//                               prefixIcon: const Icon(Icons.lock),
//                               hintText: 'Enter your password',
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscurePassword
//                                       ? Icons.visibility_off
//                                       : Icons.visibility,
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _obscurePassword = !_obscurePassword;
//                                   });
//                                 },
//                               ),
//                             ),
//                             textInputAction: TextInputAction.done,
//                             enabled: !_isLoading,
//                             onFieldSubmitted: (_) => _handleLogin(),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return AppConstants.validationRequired;
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: AppTheme.spacingL),

//                           // Error Message
//                           if (_errorMessage != null)
//                             Container(
//                               padding: const EdgeInsets.all(AppTheme.spacingM),
//                               decoration: BoxDecoration(
//                                 color: AppTheme.errorColor.withOpacity(0.1),
//                                 borderRadius:
//                                     BorderRadius.circular(AppTheme.radiusM),
//                                 border: Border.all(
//                                   color: AppTheme.errorColor,
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.error_outline,
//                                     color: AppTheme.errorColor,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: AppTheme.spacingS),
//                                   Expanded(
//                                     child: Text(
//                                       _errorMessage!,
//                                       style: TextStyle(
//                                         color: AppTheme.errorColor,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           if (_errorMessage != null)
//                             const SizedBox(height: AppTheme.spacingM),

//                           // Login Button
//                           ElevatedButton(
//                             onPressed: _isLoading ? null : _handleLogin,
//                             child: _isLoading
//                                 ? const SizedBox(
//                                     height: 20,
//                                     width: 20,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.white),
//                                     ),
//                                   )
//                                 : const Text('Login'),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: AppTheme.spacingL),

//                 // Info Card
//                 Card(
//                   color: AppTheme.infoColor.withOpacity(0.1),
//                   child: Padding(
//                     padding: const EdgeInsets.all(AppTheme.spacingM),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.info_outline,
//                               color: AppTheme.infoColor,
//                               size: 20,
//                             ),
//                             const SizedBox(width: AppTheme.spacingS),
//                             Text(
//                               'Test Credentials',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: AppTheme.infoColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: AppTheme.spacingS),
//                         Text(
//                           'Instructor:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: AppTheme.textPrimaryColor,
//                           ),
//                         ),
//                         Text(
//                           'Username: ${AppConstants.adminUsername}',
//                           style: TextStyle(
//                             color: AppTheme.textSecondaryColor,
//                           ),
//                         ),
//                         Text(
//                           'Password: ${AppConstants.adminPassword}',
//                           style: TextStyle(
//                             color: AppTheme.textSecondaryColor,
//                           ),
//                         ),
//                         const SizedBox(height: AppTheme.spacingS),
//                         Text(
//                           'Student credentials will be created by instructor.',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppTheme.textSecondaryColor,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
