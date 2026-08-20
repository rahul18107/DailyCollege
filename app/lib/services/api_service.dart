import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_card.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<bool> checkStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['whatsapp'] == 'ready') {

          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getConnectedUserName() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['whatsapp'] == 'ready') {
          return data['user']?['name'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  // Add this:
  Future<bool> logout() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/logout'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final response = await http
        .get(Uri.parse('$baseUrl/groups'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch groups');
  }

  Future<List<EventCard>> fetchCards(String groupId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/cards/$groupId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => EventCard.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch cards');
  }

  Future<List<EventCard>> processMessages(String groupId) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/process'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'groupId': groupId}),
    )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List cards = data['cards'];
      return cards.map((e) => EventCard.fromJson(e)).toList();
    }
    throw Exception('Failed to process messages');
  }

  Future<String> fetchWhatsAppStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['whatsapp'];
      }
      return 'not_ready';
    } catch (_) {
      return 'not_ready';
    }
  }

  Future<String> requestPairingCode(String phoneNumber) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/request-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['code'];
    }
    throw Exception('Failed to get pairing code');
  }
}