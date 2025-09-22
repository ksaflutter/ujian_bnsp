import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/validation_helper_lokin.dart';
import '../../core/widgets/custom_button_lokin.dart';
import '../../core/widgets/custom_textfield_lokin.dart';
import '../../data/models/user_model_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../../data/services/preference_service_lokin.dart';
import '../../theme/theme_provider_lokin.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  UserModelLokin? _currentUser;
  File? _selectedProfileImage;
  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isDarkMode = false;
  bool _isReminderEnabled = false;
  String _reminderTime = "08:00";
  Timer? _reminderTimer;

  DateTime? _lastReminderShown;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await _loadUserData();
    await _loadSettings();
    _startReminderCheck();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _checkAndShowReminder() {
    if (!_isReminderEnabled) return;
    final now = DateTime.now();

    if (_lastReminderShown != null) {
      final secondsSinceLast = now.difference(_lastReminderShown!).inSeconds;
      if (secondsSinceLast < 60) {
        return;
      }
    }

    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (timeString == _reminderTime && mounted) {
      _lastReminderShown = now;
      _showInAppReminder();
    }
  }

  void _startReminderCheck() {
    _reminderTimer?.cancel();
    _reminderTimer = null;

    if (!_isReminderEnabled) return;

    final now = DateTime.now();
    _checkAndShowReminder();

    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute)
            .add(const Duration(minutes: 1));
    final initialDelay = nextMinute.difference(now);

    _reminderTimer = Timer(initialDelay, () {
      _checkAndShowReminder();

      _reminderTimer?.cancel();
      _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _checkAndShowReminder();
      });
    });
  }

  void _showInAppReminder() {
    if (!mounted) return;

    // Show SnackBar only (Dialog removed)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.alarm,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏰ Pengingat Absen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Waktunya untuk melakukan absensi!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColorsLokin.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'ABSEN',
          textColor: Colors.white,
          onPressed: () {
            DefaultTabController.of(context).animateTo(0);
          },
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = _preferenceService.getUser();
      _nameController.text = _currentUser?.name ?? '';

      final result = await _authRepository.getProfile();
      if (result.isSuccess && result.user != null) {
        setState(() {
          _currentUser = result.user;
          _nameController.text = result.user!.name;
        });
        await _preferenceService.saveUser(result.user!);
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isDarkMode = _preferenceService.isDarkMode;
      _isReminderEnabled = _preferenceService.isReminderEnabled;
      _reminderTime = _preferenceService.reminderTime;
    });
  }

  Future<void> _refreshUserData() async {
    await _loadUserData();
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih foto: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedProfileImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _authRepository.updateProfilePhoto(_selectedProfileImage!.path);
      if (result.isSuccess) {
        _showSuccessSnackBar('Foto profil berhasil diperbarui');
        await _loadUserData();
      } else {
        _showErrorSnackBar(result.message ?? 'Gagal memperbarui foto profil');
        setState(() {
          _selectedProfileImage = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memperbarui foto: $e');
      setState(() {
        _selectedProfileImage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authRepository.updateProfile(
        name: _nameController.text,
      );

      if (result.isSuccess) {
        setState(() {
          _currentUser = result.user;
          _isEditingName = false;
        });
        _showSuccessSnackBar('Nama berhasil diperbarui');
        if (result.user != null) {
          await _preferenceService.saveUser(result.user!);
        }
      } else {
        _showErrorSnackBar(result.message ?? 'Gagal memperbarui nama');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memperbarui nama: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_reminderTime.split(':')[0]),
        minute: int.parse(_reminderTime.split(':')[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColorsLokin.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _reminderTime = formattedTime;
      });
      await _preferenceService.setReminderTime(formattedTime);

      if (_isReminderEnabled) {
        _startReminderCheck();
        _checkAndShowReminder();
      }

      _showSuccessSnackBar('Waktu pengingat diatur ke $formattedTime');
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _preferenceService.setDarkMode(value);

    if (mounted) {
      context.read<ThemeProvider>().toggleTheme();
    }

    _showSuccessSnackBar('Tema berhasil diubah');
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() {
      _isReminderEnabled = value;
    });
    await _preferenceService.setReminderEnabled(value);

    if (value) {
      _startReminderCheck();
      _checkAndShowReminder();
      _showSuccessSnackBar('Pengingat diaktifkan pada pukul $_reminderTime');
    } else {
      _reminderTimer?.cancel();
      _reminderTimer = null;
      _showSuccessSnackBar('Pengingat dinonaktifkan');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLokin.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authRepository.logout();
        await _preferenceService.clearAllUserData();
        _reminderTimer?.cancel();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        _showErrorSnackBar('Gagal logout: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColorsLokin.primary, AppColorsLokin.secondary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
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
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
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
              IconButton(
                icon: Icon(
                  _isEditingName ? Icons.close : Icons.edit,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isEditingName = !_isEditingName;
                    if (!_isEditingName) {
                      _nameController.text = _currentUser?.name ?? '';
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditingName) ...[
            Form(
              key: _formKey,
              child: CustomTextFieldLokin(
                controller: _nameController,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap Anda',
                hintText: 'Nama Lengkap',
                prefixIcon: Icons.person,
                validator: ValidationHelperLokin.validateName,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Simpan Perubahan',
              onPressed: _updateUserName,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColorsLokin.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorsLokin.textPrimary,
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
              onChanged: _toggleDarkMode,
              activeColor: AppColorsLokin.primary,
            ),
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Pengingat Absen',
            subtitle: _isReminderEnabled
                ? 'Aktif pada pukul $_reminderTime'
                : 'Nonaktif',
            trailing: Switch(
              value: _isReminderEnabled,
              onChanged: _toggleReminder,
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
              onTap: _showTimePicker,
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      child: CustomButton(
        text: 'Logout',
        onPressed: _logout,
        backgroundColor: AppColorsLokin.error,
      ),
    );
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
