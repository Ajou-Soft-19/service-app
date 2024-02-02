import 'dart:async';
import 'dart:convert';

import 'package:am_app/model/api/exception/exception_message.dart';
import 'package:am_app/model/api/exception/token_expired.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'dto/jwt_token_info.dart';

class TokenApiUtils {
  final loginServerUrl = dotenv.env['LOGIN_SERVER_URL']!;
  final timeoutTime = const Duration(seconds: 5);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> getHeaders({bool authRequired = false}) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    headers['Access-Control-Allow-Origin'] = "https://bandallgom.com";

    if (authRequired) {
      String? accessToken = await _storage.read(key: 'accessToken');
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  Future<void> checkLoginStatus(UserProvider userProvider) async {
    String? accessToken = await _storage.read(key: 'accessToken');
    String? refreshToken = await _storage.read(key: 'refreshToken');

    if (refreshToken == null || accessToken == null) {
      await _storage.deleteAll();
      await userProvider.deleteState(true);
      throw TokenExpiredException(ExceptionMessage.TOKEN_EXPIRED);
    }

    if (!JwtDecoder.isExpired(accessToken)) {
      return;
    }

    if (JwtDecoder.isExpired(refreshToken)) {
      await _storage.deleteAll();
      await userProvider.deleteState(true);
      throw TokenExpiredException(ExceptionMessage.TOKEN_EXPIRED);
    }

    await refreshTokens(userProvider);
  }

  Future<void> refreshTokens(UserProvider userProvider) async {
    final url = Uri.parse('$loginServerUrl/api/account/refresh');
    final accessToken = await _storage.read(key: 'accessToken');
    final refreshToken = await _storage.read(key: 'refreshToken');

    final headers = await getHeaders();
    final body = jsonEncode({
      'accessToken': accessToken!,
      'refreshToken': refreshToken!,
    });
    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    await updateTokenInfo(response, userProvider);
  }

  Future<void> updateTokenInfo(
      http.Response response, UserProvider userProvider) async {
    final tokenInfo =
        JwtTokenInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    final accessTokenInfo = JwtDecoder.decode(tokenInfo.accessToken!);

    if (accessTokenInfo['username'] == null) {
      await userProvider.deleteState(true);
      throw TokenExpiredException(ExceptionMessage.TOKEN_EXPIRED);
    }

    await userProvider.updateState(
        accessTokenInfo['username'],
        accessTokenInfo['sub'],
        accessTokenInfo['auth'],
        tokenInfo.accessToken,
        tokenInfo.refreshToken,
        null);
  }

  Future<void> isResponseSuccess(http.Response response) async {
    if (response.statusCode == 500) {
      throw Exception('Server error');
    }

    if (response.statusCode != 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['data']['errMsg']);
    }
  }

  Future<void> isResponseSuccessWithProvider(
      http.Response response, UserProvider userProvider) async {
    if (response.statusCode == 500) {
      throw Exception(response.body);
    }

    if (response.statusCode == 401) {
      await _storage.deleteAll();
      await userProvider.deleteState(true);
      throw TokenExpiredException(ExceptionMessage.TOKEN_EXPIRED);
    }

    if (response.statusCode != 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(json['data']['errMsg']);
    }
  }
}
