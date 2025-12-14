import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'results_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isAnalyzing = true;
  String _currentStep = 'Initializing...';
  double _progress = 0.0;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<AnalysisStep> _steps = [
    AnalysisStep('Connecting to AI', Icons.cloud_outlined, 0.2),
    AnalysisStep('Uploading image', Icons.upload_outlined, 0.4),
    AnalysisStep('AI analyzing damage', Icons.auto_awesome, 0.7),
    AnalysisStep('Calculating fair price', Icons.calculate_outlined, 0.9),
    AnalysisStep('Generating report', Icons.description_outlined, 1.0),
  ];

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _analyzeImage();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    try {
      // Step 1: Check backend
      await _updateStep(0);
      await Future.delayed(const Duration(milliseconds: 800));

      final isHealthy = await _apiService.checkHealth();
      if (!isHealthy) {
        throw Exception('Backend not running');
      }

      // Step 2: Upload
      await _updateStep(1);
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Analyze
      await _updateStep(2);
      final result = await _apiService.predict(widget.imagePath);

      // Step 4: Calculate
      await _updateStep(3);
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Generate report
      await _updateStep(4);
      await Future.delayed(const Duration(milliseconds: 600));

      // Success haptic
      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResultsScreen(
                  imagePath: widget.imagePath,
                  prediction: {
                    'class': result.damageType,
                    'confidence': result.confidence,
                    'description': result.description,
                    'emoji': result.emoji,
                    'colorHex': result.colorHex,
                    'allPredictions': result.allPredictions,
                  },
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString().contains('Backend')
              ? 'Backend not running.\n\nStart it with:\ncd ml/backend\npython3 main.py'
              : 'Error: $e';
          _currentStep = 'Analysis Failed';
        });
      }
    }
  }

  Future<void> _updateStep(int index) async {
    if (index < _steps.length) {
      setState(() {
        _currentStepIndex = index;
        _currentStep = _steps[index].label;
        _progress = _steps[index].progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0FDFA),
              const Color(0xFFCCFBF1),
              const Color(0xFFD1FAE5).withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF065F46),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Analyzing',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image preview with mint border
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(widget.imagePath),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (_isAnalyzing) ...[
                        // Animated scanning indicator
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Progress indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 10,
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    backgroundColor: const Color(0xFFD1FAE5),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF10B981),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Current step
                        Text(
                          _currentStep,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'AI is verifying your product...',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 44),

                        // Steps list
                        _buildStepsList(),
                      ] else ...[
                        // Error state
                        Icon(
                          Icons.error_outline_rounded,
                          size: 90,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _currentStep,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red.shade700,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Go Back'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _isAnalyzing = true;
                                  _errorMessage = null;
                                  _currentStep = 'Retrying...';
                                  _progress = 0.0;
                                  _currentStepIndex = 0;
                                });
                                _analyzeImage();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < _currentStepIndex;
          final isCurrent = index == _currentStepIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompleted || isCurrent
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                          )
                        : null,
                    color: isCompleted || isCurrent
                        ? null
                        : Colors.grey.shade200,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : step.icon,
                    color: isCompleted || isCurrent
                        ? Colors.white
                        : Colors.grey.shade400,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : isCurrent
                          ? const Color(0xFF065F46)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AnalysisStep {
  final String label;
  final IconData icon;
  final double progress;

  AnalysisStep(this.label, this.icon, this.progress);
}
