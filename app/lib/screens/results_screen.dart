import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/resale_calculator.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> prediction;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.prediction,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  final ResaleCalculator _calculator = ResaleCalculator();
  String _selectedPhone = 'iPhone 14 Pro';
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final Map<String, Color> _damageColors = {
    'crack': const Color(0xFFEF4444), // Red
    'dent': const Color(0xFFF97316), // Orange
    'scratch': const Color(0xFFFBBF24), // Yellow
    'pristine': const Color(0xFF10B981), // Mint green
  };

  final Map<String, IconData> _damageIcons = {
    'crack': Icons.phone_disabled_rounded,
    'dent': Icons.warning_rounded,
    'scratch': Icons.grid_on_rounded,
    'pristine': Icons.verified_rounded,
  };

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
    
    // Success haptic
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String get _detectedClass => widget.prediction['class'] ?? 'unknown';
  double get _confidence => (widget.prediction['confidence'] ?? 0.0) * 100;

  @override
  Widget build(BuildContext context) {
    final valuation = _calculator.calculateValue(_selectedPhone, _detectedClass);
    
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
              // Header
              _buildHeader(),
              
              // Scrollable content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview
                        _buildImagePreview(),
                        
                        const SizedBox(height: 32),
                        
                        // Main result card
                        _buildMainResultCard(),
                        
                        const SizedBox(height: 24),
                        
                        // All probabilities
                        _buildAllProbabilities(),
                        
                        const SizedBox(height: 24),
                        
                        // Phone selector
                        _buildPhoneSelector(),
                        
                        const SizedBox(height: 24),
                        
                        // Value calculator
                        _buildValueCalculator(valuation),
                        
                        const SizedBox(height: 24),
                        
                        // Repair costs (if damaged)
                        if (_detectedClass != 'pristine')
                          _buildRepairCosts(),
                        
                        if (_detectedClass != 'pristine')
                          const SizedBox(height: 24),
                        
                        // Recommendations
                        _buildRecommendations(),
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        _buildActionButtons(),
                        
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF065F46)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0FDFA),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Verification Report',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _damageColors[_detectedClass]!.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _damageColors[_detectedClass]!,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainResultCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _damageColors[_detectedClass]!.withOpacity(0.1),
            _damageColors[_detectedClass]!.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _damageColors[_detectedClass]!.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _damageColors[_detectedClass]!,
                  _damageColors[_detectedClass]!.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _damageColors[_detectedClass]!.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _damageIcons[_detectedClass],
              size: 48,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Result text
          Text(
            _getResultTitle(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _damageColors[_detectedClass],
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Confidence
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _damageColors[_detectedClass]!.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_confidence.toStringAsFixed(1)}% Confidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _damageColors[_detectedClass],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            _getResultDescription(),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllProbabilities() {
    final probabilities = widget.prediction['probabilities'] as Map<String, dynamic>?;
    
    if (probabilities == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detection Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          ...probabilities.entries.map((entry) {
            final probability = (entry.value * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _damageIcons[entry.key],
                            size: 18,
                            color: _damageColors[entry.key],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${probability.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _damageColors[entry.key],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: probability / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _damageColors[entry.key]!,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhoneSelector() {
    final phones = ResaleCalculator.baseValues.keys.toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Phone Model',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedPhone,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF10B981)),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
              items: phones.map((phone) {
                return DropdownMenuItem(
                  value: phone,
                  child: Text(phone),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedPhone = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCalculator(Map<String, dynamic> valuation) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF6EE7B7).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fair Price Estimate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Base value
          _buildValueRow(
            'Original Value',
            '\$${valuation['baseValue']}',
            Colors.grey.shade700,
            false,
          ),
          
          const SizedBox(height: 12),
          
          // Damage impact
          if (valuation['lossPercentage'] > 0) ...[
            _buildValueRow(
              'Damage Impact',
              '-${valuation['lossPercentage']}%',
              const Color(0xFFEF4444),
              false,
            ),
            const SizedBox(height: 12),
            _buildValueRow(
              'Value Loss',
              '-\$${valuation['loss']}',
              const Color(0xFFEF4444),
              false,
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),
          ],
          
          // Current value
          _buildValueRow(
            'Current Fair Value',
            '\$${valuation['currentValue']}',
            const Color(0xFF10B981),
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value, Color color, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 26 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRepairCosts() {
    final costs = _getRepairCosts();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF97316).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_rounded,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estimated Repair Costs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repair Range',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  costs,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _getRecommendations();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF60A5FA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Smart Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 24),
            label: const Text(
              'Scan Another Device',
              style: TextStyle(fontSize: 17),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
          ),
        ),
        
        const SizedBox(height: 14),
        
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded, size: 24),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 17),
            ),
          ),
        ),
      ],
    );
  }

  String _getResultTitle() {
    switch (_detectedClass) {
      case 'pristine':
        return 'Excellent Condition! ✓';
      case 'scratch':
        return 'Minor Scratches';
      case 'dent':
        return 'Dent Detected';
      case 'crack':
        return 'Screen Crack Found';
      default:
        return 'Analysis Complete';
    }
  }

  String _getResultDescription() {
    switch (_detectedClass) {
      case 'pristine':
        return 'This device appears to be in excellent condition with no visible damage. Great find!';
      case 'scratch':
        return 'Surface scratches detected. These are cosmetic but may affect resale value slightly.';
      case 'dent':
        return 'Body dent detected. This may indicate impact damage. Check functionality carefully.';
      case 'crack':
        return 'Screen crack detected. This significantly impacts value and may affect functionality.';
      default:
        return 'AI analysis completed successfully.';
    }
  }

  String _getRepairCosts() {
    switch (_detectedClass) {
      case 'crack':
        return '\$100 - \$300';
      case 'dent':
        return '\$80 - \$200';
      case 'scratch':
        return '\$50 - \$120';
      default:
        return 'N/A';
    }
  }

  List<String> _getRecommendations() {
    switch (_detectedClass) {
      case 'pristine':
        return [
          'This is a fair price for excellent condition',
          'Verify all features work properly before buying',
          'Check battery health if possible',
          'Confirm warranty status and purchase proof',
          'Ask about original accessories included',
        ];
      case 'scratch':
        return [
          'Negotiate 10-15% off asking price',
          'Scratches are cosmetic but reduce resale value',
          'Consider using a case to cover marks',
          'Verify screen and camera are not affected',
          'Ask seller about cause of scratches',
        ];
      case 'dent':
        return [
          'Negotiate 20-25% off asking price',
          'Check for water damage indicators',
          'Test all buttons and features thoroughly',
          'Inspect internal components if possible',
          'Consider repair costs in final offer',
        ];
      case 'crack':
        return [
          'Negotiate 30-40% off asking price',
          'Factor in screen replacement cost (\$100-300)',
          'Check if crack affects touch functionality',
          'Inspect for glass fragments that could spread',
          'Consider if repair is worth the total cost',
          'Ask if still under warranty or AppleCare',
        ];
      default:
        return ['Verify device thoroughly before purchase'];
    }
  }
}