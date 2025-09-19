import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/date_helper_lokin.dart';
import '../../core/utils/validation_helper_lokin.dart';
import '../../core/widgets/custom_button_lokin.dart';
import '../../core/widgets/custom_textfield_lokin.dart';
import '../../core/widgets/loading_widget_lokin.dart';
import '../../data/repositories/attendance_repository_lokin.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _attendanceRepository = AttendanceRepository();

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedReason = 'Sakit';

  final List<String> _predefinedReasons = [
    'Sakit',
    'Urusan Keluarga',
    'Urusan Pribadi',
    'Dinas Luar',
    'Cuti',
    'Lainnya',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColorsLokin.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitPermission() async {
    print('=== SUBMIT PERMISSION START ===');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    // Validate selected date
    final dateValidationError =
        ValidationHelperLokin.validateDate(_selectedDate);
    if (dateValidationError != null) {
      _showErrorSnackBar(dateValidationError);
      return;
    }

    // Check if custom reason is selected but empty
    if (_selectedReason == 'Lainnya' && _reasonController.text.trim().isEmpty) {
      _showErrorSnackBar('Mohon isi alasan izin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reason = _selectedReason == 'Lainnya'
          ? _reasonController.text.trim()
          : _selectedReason;

      // PERBAIKAN: Format tanggal untuk API (yyyy-MM-dd)
      final formattedDate = DateHelperLokin.formatDateForApi(_selectedDate);

      print('Selected date: $_selectedDate');
      print('Formatted date for API: $formattedDate');
      print('Reason: $reason');

      // Validate parameters before sending
      final validationErrors = ValidationHelperLokin.validatePermissionParams(
        date: formattedDate,
        reason: reason,
      );

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.values.first;
        print('Validation error: $errorMessage');
        _showErrorSnackBar(errorMessage!);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Calling API with date: $formattedDate, reason: $reason');

      final result = await _attendanceRepository.submitPermission(
        date: formattedDate,
        reason: reason,
      );

      print('API result - success: ${result.isSuccess}');
      print('API result - message: ${result.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isSuccess) {
          _showSuccessDialog(result.message);
          _resetForm();
        } else {
          _showErrorSnackBar(result.message);
        }
      }
    } catch (e) {
      print('Exception in _submitPermission: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedReason = 'Sakit';
      _reasonController.clear();
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: add lottie
            const Icon(
              Icons.check_circle,
              color: AppColorsLokin.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Berhasil!',
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColorsLokin.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          colors: [AppColorsLokin.warning, AppColorsLokin.secondary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pengajuan Izin',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ajukan izin untuk kehadiran Anda',
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

  Widget _buildPermissionForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            Text(
              'Tanggal Izin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsLokin.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColorsLokin.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColorsLokin.background,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColorsLokin.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateHelperLokin.formatDateWithDay(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColorsLokin.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColorsLokin.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reason Selection
            Text(
              'Alasan Izin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsLokin.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            // Predefined reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      if (reason != 'Lainnya') {
                        _reasonController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColorsLokin.warning
                          : AppColorsLokin.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColorsLokin.warning
                            : AppColorsLokin.border,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColorsLokin.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom reason input (only if 'Lainnya' is selected)
            if (_selectedReason == 'Lainnya') ...[
              const SizedBox(height: 16),
              CustomTextFieldLokin(
                controller: _reasonController,
                label: 'Alasan Khusus',
                hint: 'Tulis alasan izin Anda...',
                maxLines: 3,
                validator: (value) =>
                    ValidationHelperLokin.validateReason(value),
              ),
            ],

            const SizedBox(height: 24),

            // Warning Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsLokin.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColorsLokin.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penting!',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColorsLokin.warning,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan tanggal dan alasan izin sudah benar. Setelah diajukan, Anda tidak dapat melakukan absensi pada tanggal tersebut.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColorsLokin.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const LoadingWidgetLokin()
                  : CustomButton(
                      text: 'Ajukan Izin',
                      onPressed: _submitPermission,
                      backgroundColor: AppColorsLokin.warning,
                      icon: Icons.send,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionGuide() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorsLokin.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: AppColorsLokin.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Panduan Pengajuan Izin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorsLokin.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            '1. Pilih tanggal yang Anda ingin ajukan izin',
            '2. Pilih atau tulis alasan izin yang jelas',
            '3. Pastikan data sudah benar sebelum mengirim',
            '4. Izin hanya dapat diajukan untuk hari ini atau masa depan',
            '5. Setelah izin disetujui, Anda tidak dapat absen pada tanggal tersebut',
          ].map(
            (guide) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: AppColorsLokin.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guide,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColorsLokin.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColorsLokin.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildPermissionForm(),
            const SizedBox(height: 16),
            _buildPermissionGuide(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
