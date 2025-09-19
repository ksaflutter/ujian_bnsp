import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokinid_app/data/models/training_model_lokin.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/validation_helper_lokin.dart';
import '../../core/widgets/custom_button_lokin.dart';
import '../../core/widgets/custom_textfield_lokin.dart';
import '../../core/widgets/loading_widget_lokin.dart';
import '../../data/models/batch_model_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../main/main_navigation_lokin.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Training dan Batch lists
  List<TrainingModel> _trainings = [];
  List<BatchModel> _batches = [];
  int? _selectedTrainingId;
  int? _selectedBatchId;
  String _selectedGender = 'L'; // FIXED: Use API format directly
  File? _selectedProfileImage;

  bool _isLoadingData = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_dataLoaded) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      print('Loading initial data...');

      final trainingsResult = await _authRepository.getTrainings();
      print('Trainings result: success=${trainingsResult.isSuccess}');

      if (trainingsResult.isSuccess && trainingsResult.data != null) {
        setState(() {
          _trainings = trainingsResult.data as List<TrainingModel>;
        });
        print('Loaded ${_trainings.length} trainings');
      } else {
        _showErrorSnackBar(
            'Gagal memuat data pelatihan: ${trainingsResult.message}');
        print('Failed to load trainings: ${trainingsResult.message}');
      }

      final batchesResult =
          await _authRepository.getBatches(_selectedTrainingId!);
      print('Batches result: success=${batchesResult.isSuccess}');

      if (batchesResult.isSuccess && batchesResult.data != null) {
        setState(() {
          _batches = batchesResult.data as List<BatchModel>;
          _dataLoaded = true;
        });
        print('Loaded ${_batches.length} batches');
      } else {
        _showErrorSnackBar('Gagal memuat data batch: ${batchesResult.message}');
        print('Failed to load batches: ${batchesResult.message}');
      }
    } catch (e) {
      print('Error loading initial data: $e');
      _showErrorSnackBar('Gagal memuat data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih foto: $e');
    }
  }

  Future<void> _handleRegister() async {
    print('=== REGISTER ATTEMPT ===');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    if (_selectedTrainingId == null) {
      _showErrorSnackBar('Silakan pilih pelatihan');
      print('No training selected');
      return;
    }

    if (_selectedBatchId == null) {
      _showErrorSnackBar('Silakan pilih batch');
      print('No batch selected');
      return;
    }

    if (!_agreeToTerms) {
      _showErrorSnackBar('Anda harus menyetujui syarat dan ketentuan');
      print('Terms not agreed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting registration with:');
      print('Name: ${_nameController.text.trim()}');
      print('Email: ${_emailController.text.trim()}');
      print('Training ID: $_selectedTrainingId');
      print('Batch ID: $_selectedBatchId');
      print('Gender: $_selectedGender'); // This should be L or P

      final result = await _authRepository.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        trainingId: _selectedTrainingId!,
        batchId: _selectedBatchId!,
        gender: _selectedGender, // FIXED: Add gender parameter
      );

      print('Registration result: success=${result.isSuccess}');
      print('Registration message: ${result.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessDialog(result.message);
        } else {
          _showErrorSnackBar(result.allErrors);
          print('Registration failed: ${result.allErrors}');
        }
      }
    } catch (e) {
      print('Registration exception: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColorsLokin.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Registrasi Berhasil!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsLokin.success,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Lanjutkan',
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigation(),
      ),
      (route) => false,
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
                  color: AppColorsLokin.border,
                  width: 2,
                ),
                color: AppColorsLokin.surface,
              ),
              child: _selectedProfileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        _selectedProfileImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person_add,
                      size: 40,
                      color: AppColorsLokin.textSecondary,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColorsLokin.primary,
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

  Widget _buildTrainingDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program Pelatihan *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColorsLokin.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColorsLokin.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedTrainingId,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'Pilih program pelatihan',
              prefixIcon: Icon(Icons.school_outlined,
                  color: AppColorsLokin.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _trainings.map((training) {
              return DropdownMenuItem<int>(
                value: training.id,
                child: Text(
                  training.title,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTrainingId = value;
              });
              print('Selected training ID: $value');
            },
            validator: (value) {
              if (value == null) {
                return 'Pelatihan wajib dipilih';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch Pelatihan *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColorsLokin.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColorsLokin.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedBatchId,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'Pilih batch pelatihan',
              prefixIcon: Icon(Icons.groups_outlined,
                  color: AppColorsLokin.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _batches.map((batch) {
              return DropdownMenuItem<int>(
                value: batch.id,
                child: Text(
                  batch.displayName,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBatchId = value;
              });
              print('Selected batch ID: $value');
            },
            validator: (value) {
              if (value == null) {
                return 'Batch wajib dipilih';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin *',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColorsLokin.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Laki-laki'),
                value: 'L', // FIXED: Use API format
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                  print('Selected gender: $value');
                },
                activeColor: AppColorsLokin.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Perempuan'),
                value: 'P', // FIXED: Use API format
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                  print('Selected gender: $value');
                },
                activeColor: AppColorsLokin.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData && !_dataLoaded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: LoadingWidgetLokin(message: 'Memuat data pelatihan...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorsLokin.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar Akun',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorsLokin.textPrimary,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileImagePicker(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Pilih Foto Profil (Opsional)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColorsLokin.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextFieldLokin(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap Anda',
                    prefixIcon: Icons.person_outline,
                    validator: ValidationHelperLokin.validateName,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFieldLokin(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Masukkan email Anda',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidationHelperLokin.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFieldLokin(
                    controller: _passwordController,
                    label: 'Buat Password',
                    hint: 'Masukkan password (min. 6 karakter)',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColorsLokin.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: ValidationHelperLokin.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFieldLokin(
                    controller: _confirmPasswordController,
                    label: 'Konfirmasi Password',
                    hint: 'Masukkan ulang password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColorsLokin.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      return ValidationHelperLokin.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTrainingDropdown(),
                  const SizedBox(height: 16),
                  _buildBatchDropdown(),
                  const SizedBox(height: 16),
                  _buildGenderSelection(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColorsLokin.primary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  const TextSpan(
                                    text: 'Saya menyetujui ',
                                    style: TextStyle(
                                        color: AppColorsLokin.textSecondary),
                                  ),
                                  TextSpan(
                                    text: 'Syarat dan Ketentuan',
                                    style: TextStyle(
                                      color: AppColorsLokin.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' yang berlaku',
                                    style: TextStyle(
                                        color: AppColorsLokin.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const LoadingWidgetLokin()
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                AppColorsLokin.primary,
                                AppColorsLokin.primary.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Register',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColorsLokin.textSecondary,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AppColorsLokin.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
