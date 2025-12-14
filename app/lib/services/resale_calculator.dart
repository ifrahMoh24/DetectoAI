class ResaleCalculator {
  static const Map<String, double> phoneValues = {
    'iPhone 14 Pro Max': 1099.0,
    'iPhone 14 Pro': 999.0,
    'iPhone 14': 799.0,
    'iPhone 13': 599.0,
    'iPhone 12': 499.0,
    'Samsung Galaxy S23': 799.0,
    'Samsung Galaxy S22': 599.0,
    'Google Pixel 7': 599.0,
    'Generic Phone': 500.0,
  };

  // Alias for baseValues (used by results_screen)
  static Map<String, double> get baseValues => phoneValues;

  static const Map<String, double> damageImpact = {
    'pristine': 1.0,
    'scratch': 0.85,
    'dent': 0.75,
    'crack': 0.60,
  };

  // Instance method for calculateValue (used by results_screen)
  // Returns Map for compatibility with new results_screen
  Map<String, dynamic> calculateValue(String phoneModel, String damageType) {
    final estimate = calculate(
      phoneModel: phoneModel,
      damageType: damageType,
      confidence: 1.0,
    );
    return {
      'baseValue': estimate.baseValue.toInt(),
      'currentValue': estimate.estimatedValue.toInt(),
      'loss': estimate.valueLost.toInt(),
      'lossPercentage': estimate.percentageLost.toInt(),
    };
  }

  static ValueEstimate calculate({
    required String phoneModel,
    required String damageType,
    required double confidence,
  }) {
    final baseValue = phoneValues[phoneModel] ?? phoneValues['Generic Phone']!;
    final multiplier = damageImpact[damageType] ?? 0.5;
    final estimatedValue = baseValue * multiplier;
    final valueLost = baseValue - estimatedValue;
    final percentageLost = ((1 - multiplier) * 100);

    return ValueEstimate(
      baseValue: baseValue,
      estimatedValue: estimatedValue,
      valueLost: valueLost,
      percentageLost: percentageLost,
      damageType: damageType,
      confidence: confidence,
    );
  }

  static RepairEstimate getRepairCost(String damageType) {
    switch (damageType) {
      case 'crack':
        return RepairEstimate(
          minCost: 100.0,
          maxCost: 300.0,
          description: 'Screen replacement typically costs \$100-\$300',
          timeEstimate: '1-2 hours',
        );
      case 'dent':
        return RepairEstimate(
          minCost: 50.0,
          maxCost: 200.0,
          description: 'Body repair costs \$50-\$200',
          timeEstimate: '1-3 hours',
        );
      case 'scratch':
        return RepairEstimate(
          minCost: 30.0,
          maxCost: 100.0,
          description: 'Scratch removal: \$30-\$100',
          timeEstimate: '30 minutes - 1 hour',
        );
      case 'pristine':
        return RepairEstimate(
          minCost: 0.0,
          maxCost: 0.0,
          description: 'No repairs needed!',
          timeEstimate: 'N/A',
        );
      default:
        return RepairEstimate(
          minCost: 0.0,
          maxCost: 0.0,
          description: 'Cost depends on damage',
          timeEstimate: 'Unknown',
        );
    }
  }

  static List<String> getRecommendations(String damageType) {
    switch (damageType) {
      case 'crack':
        return [
          'Replace screen ASAP to prevent further damage',
          'Use screen protector after repair',
          'Consider authorized repair centers',
          'Keep receipts for warranty',
        ];
      case 'dent':
        return [
          'Check if internal components are affected',
          'Use protective case',
          'Get professional assessment',
          'Document damage with photos',
        ];
      case 'scratch':
        return [
          'Apply screen protector',
          'Use protective case',
          'Minor scratches don\'t affect functionality',
          'Professional buffing may help',
        ];
      case 'pristine':
        return [
          'Keep using screen protector',
          'Use quality protective case',
          'Regular cleaning maintains condition',
          'Phone is in excellent resale condition!',
        ];
      default:
        return ['Get professional assessment'];
    }
  }
}

class ValueEstimate {
  final double baseValue;
  final double estimatedValue;
  final double valueLost;
  final double percentageLost;
  final String damageType;
  final double confidence;

  ValueEstimate({
    required this.baseValue,
    required this.estimatedValue,
    required this.valueLost,
    required this.percentageLost,
    required this.damageType,
    required this.confidence,
  });
}

class RepairEstimate {
  final double minCost;
  final double maxCost;
  final String description;
  final String timeEstimate;

  RepairEstimate({
    required this.minCost,
    required this.maxCost,
    required this.description,
    required this.timeEstimate,
  });

  String get costRange {
    if (minCost == 0 && maxCost == 0) return 'Free';
    return '\$${minCost.toInt()}-\$${maxCost.toInt()}';
  }
}
