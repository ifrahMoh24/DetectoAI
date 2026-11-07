import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class HistoryService {
  static const _key = 'scan_history';

  Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return ScanResult.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveResult(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, result);
    // Keep at most 50 scans
    final trimmed = history.take(50).toList();
    await prefs.setString(_key, ScanResult.listToJson(trimmed));
  }

  Future<void> deleteResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((r) => r.id == id);
    await prefs.setString(_key, ScanResult.listToJson(history));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
