import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ml_service.dart';

class ApiService {
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';

  /// Check if the backend is running
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send image to backend for prediction
  Future<PredictionResult> predict(String imagePath) async {
    final uri = Uri.parse('$_baseUrl/detect');

    var request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath("file", imagePath));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Backend error: ${response.statusCode} - $resBody");
    }

    final data = jsonDecode(resBody) as Map<String, dynamic>;
    return PredictionResult.fromJson(data);
  }

  /// Static method for backwards compatibility
  static Future<Map<String, dynamic>> detectImage(File imageFile) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
    final uri = Uri.parse('$baseUrl/detect');

    var request = http.MultipartRequest("POST", uri);
    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Backend error: ${response.statusCode} - $resBody");
    }

    return jsonDecode(resBody) as Map<String, dynamic>;
  }
}
