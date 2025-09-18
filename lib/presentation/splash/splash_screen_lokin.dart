import 'package:flutter/material.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../data/repositories/auth_repository_lokin.dart';
import '../../data/services/preference_service_lokin.dart';
import '../auth/login_screen_lokin.dart';
import '../main/main_navigation_lokin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _authRepository = AuthRepository();
  final _preferenceService = PreferenceService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 2500));

      // Check authentication status
      await _checkAuthenticationStatus();
    } catch (e) {
      // If error occurs, navigate to login
      _navigateToLogin();
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      if (_authRepository.isAuthenticated) {
        // Verify session is still valid
        final isValid = await _authRepository.isSessionValid();

        if (isValid) {
          _navigateToHome();
        } else {
          // Session expired, clear data and go to login
          await _authRepository.logout();
          _navigateToLogin();
        }
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      // On error, navigate to login
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColorsLokin.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 60,
                        color: AppColorsLokin.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Name
                    Text(
                      'LokinID',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColorsLokin.primary,
                                fontSize: 32,
                              ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'PPKDJP',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColorsLokin.textSecondary,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Loading Indicator
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColorsLokin.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
