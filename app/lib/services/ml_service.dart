/// Model class for prediction results from the ML backend
class PredictionResult {
  final String damageType;
  final double confidence;
  final String description;
  final String emoji;
  final String colorHex;
  final Map<String, double> allPredictions;

  PredictionResult({
    required this.damageType,
    required this.confidence,
    required this.description,
    required this.emoji,
    required this.colorHex,
    required this.allPredictions,
  });

  /// Create PredictionResult from JSON response
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final damageType = (json['prediction'] ?? json['damage_type'] ?? 'unknown')
        .toString()
        .toLowerCase();
    final confidence = (json['confidence'] ?? 0.0).toDouble();

    // Parse all predictions if available, otherwise create default
    Map<String, double> allPredictions = {};
    if (json['all_predictions'] != null) {
      final predictions = json['all_predictions'] as Map<String, dynamic>;
      allPredictions = predictions.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } else if (json['probabilities'] != null) {
      final predictions = json['probabilities'] as Map<String, dynamic>;
      allPredictions = predictions.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } else {
      // Create default predictions based on detected damage type
      allPredictions = {
        'pristine': damageType == 'pristine'
            ? confidence
            : (1 - confidence) / 3,
        'scratch': damageType == 'scratch' ? confidence : (1 - confidence) / 3,
        'dent': damageType == 'dent' ? confidence : (1 - confidence) / 3,
        'crack': damageType == 'crack' ? confidence : (1 - confidence) / 3,
      };
    }

    return PredictionResult(
      damageType: damageType,
      confidence: confidence,
      description: _getDescription(damageType),
      emoji: _getEmoji(damageType),
      colorHex: _getColorHex(damageType),
      allPredictions: allPredictions,
    );
  }

  static String _getDescription(String damageType) {
    switch (damageType) {
      case 'crack':
        return 'Screen Crack Detected';
      case 'dent':
        return 'Dent Detected';
      case 'scratch':
        return 'Scratch Detected';
      case 'pristine':
        return 'No Damage - Pristine Condition';
      default:
        return 'Unknown Condition';
    }
  }

  static String _getEmoji(String damageType) {
    switch (damageType) {
      case 'crack':
        return '💔';
      case 'dent':
        return '📱';
      case 'scratch':
        return '⚠️';
      case 'pristine':
        return '✨';
      default:
        return '❓';
    }
  }

  static String _getColorHex(String damageType) {
    switch (damageType) {
      case 'crack':
        return '#DC2626'; // Red
      case 'dent':
        return '#F59E0B'; // Orange
      case 'scratch':
        return '#FBBF24'; // Yellow
      case 'pristine':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get severity level (0-3)
  int get severityLevel {
    switch (damageType) {
      case 'crack':
        return 3;
      case 'dent':
        return 2;
      case 'scratch':
        return 1;
      case 'pristine':
        return 0;
      default:
        return -1;
    }
  }

  /// Check if device is in good condition
  bool get isGoodCondition => damageType == 'pristine';
}
