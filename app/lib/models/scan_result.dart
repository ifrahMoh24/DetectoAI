import 'dart:convert';

class ScanResult {
  final String id;
  final String imagePath;
  final String damageType;
  final double confidence;
  final String phoneModel;
  final DateTime scannedAt;
  final Map<String, double> probabilities;

  ScanResult({
    required this.id,
    required this.imagePath,
    required this.damageType,
    required this.confidence,
    required this.phoneModel,
    required this.scannedAt,
    required this.probabilities,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'damageType': damageType,
    'confidence': confidence,
    'phoneModel': phoneModel,
    'scannedAt': scannedAt.toIso8601String(),
    'probabilities': probabilities,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] as String,
    imagePath: json['imagePath'] as String,
    damageType: json['damageType'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    phoneModel: json['phoneModel'] as String,
    scannedAt: DateTime.parse(json['scannedAt'] as String),
    probabilities: (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
  );

  static List<ScanResult> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => ScanResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ScanResult> results) =>
      jsonEncode(results.map((r) => r.toJson()).toList());
}
