import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> chat(String userId, String token, List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        "user_id": userId,
        "messages": messages,
        "target_platform": "react"
      }),
    );
    return jsonDecode(response.body);
  }
}
