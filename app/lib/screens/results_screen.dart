import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/resale_calculator.dart';
import '../services/history_service.dart';
import '../models/scan_result.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> prediction;
  final bool readOnly;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.prediction,
    this.readOnly = false,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  final ResaleCalculator _calculator = ResaleCalculator();
  final HistoryService _historyService = HistoryService();
  String _selectedPhone = 'iPhone 14 Pro';
  bool _savedToHistory = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const kBg = Color(0xFF0A0F1E);
  static const kCard = Color(0xFF1E293B);
  static const kBorder = Color(0xFF334155);
  static const kTextSub = Color(0xFF94A3B8);

  final Map<String, Color> _damageColors = {
    'crack': const Color(0xFFEF4444),
    'dent': const Color(0xFFF97316),
    'scratch': const Color(0xFFFBBF24),
    'pristine': const Color(0xFF10B981),
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
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    HapticFeedback.mediumImpact();

    if (!widget.readOnly) _autoSave();
    if (widget.readOnly) setState(() => _savedToHistory = true);
  }

  Future<void> _autoSave() async {
    final probabilities = widget.prediction['probabilities'] as Map<String, dynamic>? ?? {};
    final result = ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: widget.imagePath,
      damageType: _detectedClass,
      confidence: widget.prediction['confidence'] ?? 0.0,
      phoneModel: _selectedPhone,
      scannedAt: DateTime.now(),
      probabilities: probabilities.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
    await _historyService.saveResult(result);
    if (mounted) setState(() => _savedToHistory = true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String get _detectedClass => widget.prediction['class'] ?? 'unknown';
  double get _confidence => (widget.prediction['confidence'] ?? 0.0) * 100;
  Color get _accentColor =>
      _damageColors[_detectedClass] ?? const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final valuation = _calculator.calculateValue(_selectedPhone, _detectedClass);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 20),
                    _buildResultCard(),
                    const SizedBox(height: 16),
                    _buildProbabilitiesCard(),
                    const SizedBox(height: 16),
                    _buildPhoneSelector(),
                    const SizedBox(height: 16),
                    _buildValueCard(valuation),
                    if (_detectedClass != 'pristine') ...[
                      const SizedBox(height: 16),
                      _buildRepairCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildRecommendationsCard(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: kBg,
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBorder),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Scan Report',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            if (_savedToHistory)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 5),
                    Text('Saved',
                        style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Image.file(
            File(widget.imagePath),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor.withOpacity(0.4)),
            ),
            child: Icon(_damageIcons[_detectedClass] ?? Icons.help_outline,
                size: 44, color: _accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            _getResultTitle(),
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _accentColor,
                letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_confidence.toStringAsFixed(1)}% Confidence',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _accentColor),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _getResultDescription(),
            style: const TextStyle(fontSize: 14, color: kTextSub, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilitiesCard() {
    final probabilities =
        widget.prediction['probabilities'] as Map<String, dynamic>?;
    if (probabilities == null || probabilities.isEmpty) return const SizedBox();

    return _buildCard(
      icon: Icons.analytics_rounded,
      title: 'Detection Details',
      child: Column(
        children: probabilities.entries.map((entry) {
          final pct = (entry.value as num).toDouble() * 100;
          final color = _damageColors[entry.key] ?? Colors.grey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_damageIcons[entry.key] ?? Icons.circle,
                            size: 16, color: color),
                        const SizedBox(width: 8),
                        Text(entry.key.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhoneSelector() {
    final phones = ResaleCalculator.baseValues.keys.toList();
    return _buildCard(
      icon: Icons.phone_iphone_rounded,
      title: 'Select Phone Model',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: DropdownButton<String>(
          value: _selectedPhone,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF10B981)),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white),
          items: phones
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.lightImpact();
              setState(() => _selectedPhone = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildValueCard(Map<String, dynamic> valuation) {
    return _buildCard(
      icon: Icons.attach_money_rounded,
      title: 'Fair Price Estimate',
      accentColor: const Color(0xFF10B981),
      child: Column(
        children: [
          _valueRow('Original Value', '\$${valuation['baseValue']}',
              kTextSub, false),
          if ((valuation['lossPercentage'] as int) > 0) ...[
            const SizedBox(height: 10),
            _valueRow('Damage Impact', '-${valuation['lossPercentage']}%',
                const Color(0xFFEF4444), false),
            const SizedBox(height: 10),
            _valueRow('Value Lost', '-\$${valuation['loss']}',
                const Color(0xFFEF4444), false),
            const SizedBox(height: 14),
            const Divider(color: kBorder),
            const SizedBox(height: 14),
          ],
          _valueRow('Fair Value Now', '\$${valuation['currentValue']}',
              const Color(0xFF10B981), true),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value, Color color, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: kTextSub)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 24 : 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildRepairCard() {
    final costs = _getRepairCosts();
    return _buildCard(
      icon: Icons.build_rounded,
      title: 'Estimated Repair Cost',
      accentColor: const Color(0xFFF97316),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Repair Range',
                style: TextStyle(fontSize: 14, color: kTextSub)),
            Text(costs,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recs = _getRecommendations();
    return _buildCard(
      icon: Icons.tips_and_updates_rounded,
      title: 'Smart Tips',
      accentColor: const Color(0xFF3B82F6),
      child: Column(
        children: recs.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(rec,
                      style: const TextStyle(
                          fontSize: 14, color: kTextSub, height: 1.5)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color accentColor = const Color(0xFF10B981),
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 22),
            label: const Text('Scan Another Device'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded, size: 22),
            label: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }

  String _getResultTitle() {
    switch (_detectedClass) {
      case 'pristine':
        return 'Excellent Condition!';
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
        return 'No visible damage detected. This device appears to be in excellent condition — a great find!';
      case 'scratch':
        return 'Surface scratches detected. These are cosmetic and may slightly affect resale value.';
      case 'dent':
        return 'Body dent detected. This may indicate impact damage — check functionality carefully.';
      case 'crack':
        return 'Screen crack detected. This significantly impacts value and may affect daily use.';
      default:
        return 'AI analysis completed successfully.';
    }
  }

  String _getRepairCosts() {
    final base = ResaleCalculator.baseValues[_selectedPhone] ?? 500.0;
    switch (_detectedClass) {
      case 'crack':
        return '\$${(base * 0.10).toInt()} – \$${(base * 0.30).toInt()}';
      case 'dent':
        return '\$${(base * 0.05).toInt()} – \$${(base * 0.20).toInt()}';
      case 'scratch':
        return '\$${(base * 0.03).toInt()} – \$${(base * 0.12).toInt()}';
      default:
        return 'N/A';
    }
  }

  List<String> _getRecommendations() {
    switch (_detectedClass) {
      case 'pristine':
        return [
          'Fair price for excellent condition',
          'Verify all features work before buying',
          'Check battery health if possible',
          'Confirm warranty and purchase proof',
          'Ask about original accessories',
        ];
      case 'scratch':
        return [
          'Negotiate 10–15% off asking price',
          'Scratches are cosmetic only',
          'Verify screen and camera unaffected',
          'Use a case to cover marks',
        ];
      case 'dent':
        return [
          'Negotiate 20–25% off asking price',
          'Check for water damage indicators',
          'Test all buttons and ports thoroughly',
          'Factor repair cost into your offer',
        ];
      case 'crack':
        return [
          'Negotiate 30–40% off asking price',
          'Factor in screen replacement (\$100–300)',
          'Check if crack affects touch input',
          'Ask if still under warranty or AppleCare',
          'Inspect for spreading cracks',
        ];
      default:
        return ['Verify device thoroughly before purchase'];
    }
  }
}
