import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/validation_helper_lokin.dart';
import '../../core/widgets/custom_button_lokin.dart';
import '../../core/widgets/custom_textfield_lokin.dart';
import '../../core/widgets/loading_widget_lokin.dart';
import '../../data/models/user_model_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../../data/services/preference_service_lokin.dart';
import '../auth/login_screen_lokin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _authRepository = AuthRepository();
  final _preferenceService = PreferenceService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  UserModelLokin? _currentUser;
  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isDarkMode = false;
  bool _isReminderEnabled = true;
  String _reminderTime = '08:00';
  File? _selectedImage;
  File? _selectedProfileImage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    print('=== PROFILE SCREEN INITIALIZE ===');

    // Load user from local storage first
    _currentUser = _authRepository.currentUser;
    print('Local user found: ${_currentUser?.name}');

    if (_currentUser != null) {
      _nameController.text = _currentUser!.name;
    }

    // Load preferences
    _isDarkMode = _preferenceService.isDarkMode;
    _isReminderEnabled = _preferenceService.isReminderEnabled;
    _reminderTime = _preferenceService.reminderTime;

    // Refresh UI with local data first
    setState(() {});

    // Then refresh user data from server
    await _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    print('=== REFRESHING USER DATA FROM SERVER ===');

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authRepository.getProfile();
      print('Profile refresh result: ${result.isSuccess}');
      print('Profile refresh message: ${result.message}');

      if (result.isSuccess && result.user != null) {
        print('User data refreshed: ${result.user!.name}');
        setState(() {
          _currentUser = result.user;
          _nameController.text = result.user!.name;
        });
      } else {
        print('Failed to refresh user data: ${result.message}');
        // Show error but don't block UI if local data exists
        if (_currentUser == null) {
          _showErrorSnackBar('Gagal memuat data profil: ${result.message}');
        }
      }
    } catch (e) {
      print('Exception refreshing user data: $e');
      // Silently handle error if local data exists
      if (_currentUser == null) {
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authRepository.updateProfile(
        name: _nameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditingName = false;
        });

        if (result.isSuccess) {
          setState(() {
            _currentUser = result.user;
          });
          _showSuccessSnackBar(result.message);
        } else {
          _showErrorSnackBar(result.allErrors);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditingName = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadProfilePhoto();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih foto: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadProfilePhoto();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto: $e');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _authRepository.updateProfilePhoto(_selectedImage!.path);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessSnackBar(result.message);
          // Optionally refresh user data to get updated profile photo URL
          await _refreshUserData();
        } else {
          _showErrorSnackBar(result.allErrors);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorsLokin.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authRepository.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        _showErrorSnackBar('Gagal logout: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorsLokin.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColorsLokin.primary, AppColorsLokin.secondary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil Saya',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: _refreshUserData,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileImagePicker(),
              const SizedBox(height: 16),
              Text(
                _currentUser?.name ?? 'Memuat...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentUser?.email ?? 'Memuat...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                color: Colors.white.withOpacity(0.2),
              ),
              child: _selectedProfileImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedProfileImage!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColorsLokin.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsLokin.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informasi Pribadi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!_isEditingName)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditingName = true;
                    });
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: AppColorsLokin.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditingName) ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextFieldLokin(
                    controller: _nameController,
                    label: 'Nama',
                    hint: 'Masukkan nama Anda',
                    prefixIcon: Icons.person,
                    validator: ValidationHelperLokin.validateName,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditingName = false;
                              _nameController.text = _currentUser?.name ?? '';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColorsLokin.textSecondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Batal',
                            style:
                                TextStyle(color: AppColorsLokin.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoading
                            ? const LoadingWidgetLokin()
                            : CustomButton(
                                text: 'Simpan',
                                onPressed: _updateProfile,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildInfoItem(
              icon: Icons.person,
              title: 'Nama',
              value: _currentUser?.name ?? '-',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.email,
              title: 'Email',
              value: _currentUser?.email ?? '-',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColorsLokin.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColorsLokin.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColorsLokin.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsLokin.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: 'Mode Gelap',
            subtitle: 'Aktifkan mode gelap untuk tampilan yang nyaman di mata',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) async {
                setState(() {
                  _isDarkMode = value;
                });
                await _preferenceService.setDarkMode(value);
              },
              activeColor: AppColorsLokin.primary,
            ),
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Pengingat Absen',
            subtitle: 'Diaktifkan pada pukul $_reminderTime',
            trailing: Switch(
              value: _isReminderEnabled,
              onChanged: (value) async {
                setState(() {
                  _isReminderEnabled = value;
                });
                await _preferenceService.setReminderEnabled(value);
              },
              activeColor: AppColorsLokin.primary,
            ),
          ),
          if (_isReminderEnabled) ...[
            const Divider(),
            _buildSettingItem(
              icon: Icons.schedule,
              title: 'Waktu Pengingat',
              subtitle: _reminderTime,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showTimePicker(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsLokin.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColorsLokin.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColorsLokin.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: CustomButton(
        text: 'Logout',
        onPressed: _logout,
        backgroundColor: AppColorsLokin.error,
        textColor: Colors.white,
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_reminderTime.split(':')[0]),
        minute: int.parse(_reminderTime.split(':')[1]),
      ),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _reminderTime = formattedTime;
      });
      await _preferenceService.setReminderTime(formattedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColorsLokin.background,
      body: RefreshIndicator(
        onRefresh: _refreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildPersonalInfo(),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
