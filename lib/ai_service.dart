import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _base =
      String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

  static Future<Map<String, dynamic>?> suggest(List<List<int>> board) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'board': board}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
