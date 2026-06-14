import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _token;

  static Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> removeToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ============ AUTH ============

  static Future<Map<String, dynamic>> login(
    String login,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'login': login,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resendOtp(int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/resend-otp'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'user_id': userId}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    int userId,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/verify-otp'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'user_id': userId,
        'otp': otp,
      }),
    );

    return jsonDecode(response.body);
  }

  // Langkah 1: Kirim email reset password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/forgot-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Langkah 2: Reset password pakai token dari email
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reset-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/logout'),
      headers: await _headers(),
    );

    await removeToken();
  }

  // ============ USER / PROFILE ============

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/profile'),
    );

    final token = await getToken();

    request.headers['Accept'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (photoPath != null && photoPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', photoPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile/password'),
      headers: await _headers(),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============ FORUM ============

  static Future<Map<String, dynamic>> getForumPosts({
    String filter = 'terbaru',
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/forum?filter=$filter'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getForumPost(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/forum/$id'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createForumPost(
    Map<String, dynamic> data, {
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/forum'),
      );

      final token = await getToken();

      request.headers['Accept'] = 'application/json';

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/forum'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> likeForumPost(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/forum/$id/like'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteForumPost(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/forum/$id'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ PETS ============

  static Future<Map<String, dynamic>> getPets() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/pets'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPet(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/pets'),
    );

    final token = await getToken();

    request.headers['Accept'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (photoPath != null && photoPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePet(
    int id,
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/pets/$id'),
    );

    final token = await getToken();

    request.headers['Accept'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (photoPath != null && photoPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deletePet(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/pets/$id'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ PENGINGAT ============

  static Future<Map<String, dynamic>> getPengingat() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/pengingat'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPengingat(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/pengingat'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> selesaiPengingat(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/pengingat/$id/selesai'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deletePengingat(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/pengingat/$id'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ RIWAYAT KESEHATAN ============

  static Future<Map<String, dynamic>> getRiwayat() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/riwayat'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createRiwayat(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/riwayat'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateRiwayat(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/riwayat/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteRiwayat(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/riwayat/$id'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ CHATBOT ============

  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/chatbot/send'),
      headers: await _headers(),
      body: jsonEncode({
        'message': message,
        'session_id': sessionId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
          data['message'] ?? 'Chatbot error: ${response.statusCode}');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getChatHistory({
    String? sessionId,
  }) async {
    String url = '${ApiConstants.baseUrl}/chatbot/history';

    if (sessionId != null) {
      url += '?session_id=$sessionId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ NOTIFICATIONS ============

  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<void> markNotificationRead(int id) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
      headers: await _headers(),
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
      headers: await _headers(),
    );
  }

  static Future<void> deleteNotification(int id) async {
    await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id'),
      headers: await _headers(),
    );
  }

  // ============ SEARCH ============

  static Future<Map<String, dynamic>> search(String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/search?q=$query'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  // ============ FOLLOW / USERS ============

  static Future<Map<String, dynamic>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/search?q=$query'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/profile'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> followUser(int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/follow'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> unfollowUser(int userId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/unfollow'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFollowers(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/followers'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFollowing(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/following'),
      headers: await _headers(),
    );

    return jsonDecode(response.body);
  }
}