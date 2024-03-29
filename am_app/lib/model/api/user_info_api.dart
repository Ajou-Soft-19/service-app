import 'dart:async';
import 'dart:convert';

import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:http/http.dart' as http;

import 'dto/api_response.dart';
import 'exception/exception_message.dart';

class UserInfoApi extends TokenApiUtils {
  Future<void> createAccount(String email, String password, String username,
      String phoneNumber) async {
    final url = Uri.parse('$loginServerUrl/api/account/create');

    final response = await http
        .post(
      url,
      headers: await getHeaders(),
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'username': username,
        'phoneNumber': phoneNumber
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    if (response.statusCode == 200) {
      return;
    }

    await isResponseSuccess(response);
  }

  Future<String> getUserInfo(UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$loginServerUrl/api/whoami');
    final response = await http
        .get(url, headers: await getHeaders(authRequired: true))
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    await userProvider.updateProfileImage(json.data['profileImageUrl']);
    return utf8.decode(response.bodyBytes);
  }

  Future<void> editUsername(
      UserProvider userProvider, String newUsername) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$loginServerUrl/api/account/update-username');
    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode(<String, String>{'username': newUsername}),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
    await userProvider.updateUsername(newUsername);
  }

  Future<void> editPassword(
      UserProvider userProvider, String oldPassword, String newPassword) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$loginServerUrl/api/account/update-password');
    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode(<String, String>{
        "oldPassword": oldPassword,
        "newPassword": newPassword
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
  }
}
