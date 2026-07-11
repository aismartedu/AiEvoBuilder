import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://app.aismartedu.my.id";

  static Future<Map<String, dynamic>> chat(String prompt, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "user_id": "test_user_1",
        "prompt": prompt,
        "target_platform": "flutter"
      }),
    );
    return jsonDecode(response.body);
  }
}
