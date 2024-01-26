import 'dart:async';
import 'dart:convert';

import 'package:am_app/model/api/token_api_utils.dart';
import 'package:http/http.dart' as http;

import 'exception/exception_message.dart';

class EmailVerifyApi extends TokenApiUtils {
  Future<bool> authEmail(String email, String code) async {
    final url = Uri.parse('$loginServerUrl/api/email-verification');
    final response = await http
        .post(
      url,
      headers: await getHeaders(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    )
        .timeout(timoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    return response.statusCode == 200;
  }

  Future<void> resendAuthEmail(String email) async {
    final url =
        Uri.parse('$loginServerUrl/api/email-verification?email=$email');
    final response = await http
        .get(url, headers: await getHeaders())
        .timeout(timoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
  }
}
