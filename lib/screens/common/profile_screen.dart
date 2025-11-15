import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  double _uploadProgress = 0.0;

  File? _selectedAvatarFile;
  PlatformFile? _selectedAvatarPlatformFile;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null) {
      _emailController.text = user.email;

      // Load additional info if available
      if (user.additionalInfo != null) {
        _phoneController.text = user.additionalInfo!['phone'] ?? '';
        _bioController.text = user.additionalInfo!['bio'] ?? '';
        _addressController.text = user.additionalInfo!['address'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      if (kIsWeb) {
        // Web: use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _selectedAvatarPlatformFile = result.files.first;
            _selectedAvatarFile = null;
          });
        }
      } else {
        // Mobile/Desktop: use image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedAvatarFile = File(image.path);
            _selectedAvatarPlatformFile = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedAvatarFile == null && _selectedAvatarPlatformFile == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
      _uploadProgress = 0.0;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      final storageService = StorageService();
      String downloadUrl;

      if (kIsWeb && _selectedAvatarPlatformFile != null) {
        // Web upload
        downloadUrl = await storageService.uploadPlatformFile(
          file: _selectedAvatarPlatformFile!,
          storagePath: '${AppConstants.storageUsers}/${user.id}/avatar',
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
        );
      } else if (_selectedAvatarFile != null) {
        // Mobile/Desktop upload
        downloadUrl = await storageService.uploadAvatar(
          file: _selectedAvatarFile!,
          userId: user.id,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
        );
      } else {
        throw Exception('No file selected');
      }

      setState(() {
        _newAvatarUrl = downloadUrl;
        _isUploadingAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar uploaded successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Prepare additional info
      final additionalInfo = <String, dynamic>{
        ...?user.additionalInfo,
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'address': _addressController.text.trim(),
      };

      // Update profile
      await authService.updateProfile(
        email: _emailController.text.trim(),
        avatarUrl: _newAvatarUrl ?? user.avatarUrl,
        additionalInfo: additionalInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear selected files after save
        setState(() {
          _selectedAvatarFile = null;
          _selectedAvatarPlatformFile = null;
          _newAvatarUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatarSection(UserModel user) {
    final hasNewAvatar = _selectedAvatarFile != null || _selectedAvatarPlatformFile != null;
    final currentAvatarUrl = _newAvatarUrl ?? user.avatarUrl;

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: currentAvatarUrl != null
                  ? NetworkImage(currentAvatarUrl)
                  : null,
              child: currentAvatarUrl == null
                  ? Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: AppTheme.textOnPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: AppTheme.textOnPrimaryColor,
                  ),
                  onPressed: _isUploadingAvatar ? null : _pickAvatar,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),

        if (hasNewAvatar && !_isUploadingAvatar)
          ElevatedButton.icon(
            onPressed: _uploadAvatar,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload Avatar'),
          ),

        if (_isUploadingAvatar)
          Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

        if (hasNewAvatar)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedAvatarFile = null;
                _selectedAvatarPlatformFile = null;
              });
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('No user logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Section
                    _buildAvatarSection(user),
                    const SizedBox(height: AppTheme.spacingL),

                    // Display Name (Read-only as per requirements)
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

                            // Full Name (Read-only)
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Full Name'),
                              subtitle: Text(user.fullName),
                              trailing: Chip(
                                label: const Text('Cannot be edited'),
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            const Divider(),

                            // Username (Read-only)
                            ListTile(
                              leading: const Icon(Icons.account_circle),
                              title: const Text('Username'),
                              subtitle: Text(user.username),
                            ),
                            const Divider(),

                            // Student ID (if student, read-only)
                            if (user.studentId != null) ...[
                              ListTile(
                                leading: const Icon(Icons.badge),
                                title: const Text('Student ID'),
                                subtitle: Text(user.studentId!),
                              ),
                              const Divider(),
                            ],

                            // Role (Read-only)
                            ListTile(
                              leading: const Icon(Icons.school),
                              title: const Text('Role'),
                              subtitle: Text(
                                user.role == AppConstants.roleStudent
                                    ? 'Student'
                                    : 'Instructor',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Editable Fields
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

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                                hintText: 'Optional',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            // Bio
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                prefixIcon: Icon(Icons.info),
                                border: OutlineInputBorder(),
                                hintText: 'Tell us about yourself (optional)',
                              ),
                              maxLines: 3,
                              maxLength: 200,
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                                hintText: 'Optional',
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Profile'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
