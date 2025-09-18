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
    if (!_formKey.currentState!.validate()) return;

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

      final result = await _attendanceRepository.submitPermission(
        date: DateHelperLokin.formatDate(_selectedDate),
        reason: reason,
      );

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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Add Lottie animation here
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColorsLokin.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Izin Berhasil Diajukan!',
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
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String? _validateCustomReason(String? value) {
    if (_selectedReason == 'Lainnya') {
      return ValidationHelperLokin.validateNotEmpty(value, 'Alasan izin');
    }
    return null;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsLokin.warning,
            AppColorsLokin.warning.withOpacity(0.8)
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Izin',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ajukan izin untuk tidak hadir',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionForm() {
    return Container(
      margin: const EdgeInsets.all(20),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Pengajuan Izin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsLokin.textPrimary,
                  ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            Text(
              'Tanggal Izin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColorsLokin.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColorsLokin.border),
                  borderRadius: BorderRadius.circular(12),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

            const SizedBox(height: 20),

            // Reason Selection
            Text(
              'Alasan Izin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColorsLokin.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),

            // Predefined Reasons
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
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColorsLokin.warning
                            : AppColorsLokin.border,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColorsLokin.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom Reason Field
            if (_selectedReason == 'Lainnya') ...[
              const SizedBox(height: 16),
              CustomTextFieldLokin(
                controller: _reasonController,
                label: 'Alasan Khusus',
                hint: 'Masukkan alasan izin Anda',
                prefixIcon: Icons.edit_note,
                maxLines: 3,
                validator: _validateCustomReason,
              ),
            ],

            const SizedBox(height: 24),

            // Important Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorsLokin.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColorsLokin.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
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
