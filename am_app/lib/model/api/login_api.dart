import 'dart:async';
import 'dart:convert';

import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'exception/email_not_verified.dart';
import 'exception/exception_message.dart';
import 'dto/jwt_token_info.dart';

class LoginApi extends TokenApiUtils {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<JwtTokenInfo> idpwLogin(String email, String password) async {
    final url = Uri.parse('$loginServerUrl/api/account/auth');
    final response = await http
        .post(
      url,
      headers: await getHeaders(),
      body: jsonEncode(
        <String, String>{
          'loginType': 'EMAIL_PW',
          'email': email,
          'password': password,
        },
      ),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException("Request took too long.");
    });

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final code = json['code'];

    if (code == 410) {
      await _storage.write(key: 'email', value: email);
      throw EmailNotVerifiedException(json['data']['errMsg']);
    }

    await isResponseSuccess(response);

    return JwtTokenInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Future<void> logout() async {
    final url = Uri.parse('$loginServerUrl/api/account/logout');
    final refreshToken = await _storage.read(key: 'refreshToken');

    await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode({'refreshToken': refreshToken}),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    return;
  }

  Future<void> requestEmergencyRole(UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$loginServerUrl/api/auth/roles');
    await http
        .post(url, headers: await getHeaders(authRequired: true))
        .timeout(timeoutTime,
            onTimeout: (throw TimeoutException(
                ExceptionMessage.SERVER_NOT_RESPONDING)));
    return;
  }
}
