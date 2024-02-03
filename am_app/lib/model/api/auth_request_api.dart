import 'dart:convert';

import 'package:am_app/model/api/dto/api_response.dart';
import 'package:am_app/model/api/dto/auth_request_info.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthRequestApi extends TokenApiUtils {
  final serviceServerUrl = dotenv.env['SERVICE_SERVER_URL']!;

  Future<List<AuthRequestInfo>> getAuthRequestInfo(
      UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);

    final url = Uri.parse('$serviceServerUrl/api/auth/roles/request');

    final response =
        await http.get(url, headers: await getHeaders(authRequired: true));

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final authRequestInfos = (json.data as List)
        .map((authRequestInfoJson) =>
            AuthRequestInfo.fromJson(authRequestInfoJson))
        .toList();

    return authRequestInfos;
  }

  Future<void> approveAuthRequest(
      UserProvider userProvider, int authRequestId) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);

    final url =
        Uri.parse('$serviceServerUrl/api/auth/roles/approve/$authRequestId');

    final response =
        await http.post(url, headers: await getHeaders(authRequired: true));

    await isResponseSuccess(response);
  }

  Future<void> rejectAuthRequest(
      UserProvider userProvider, int authRequestId) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);

    final url =
        Uri.parse('$serviceServerUrl/api/auth/roles/reject/$authRequestId');

    final response =
        await http.post(url, headers: await getHeaders(authRequired: true));

    await isResponseSuccess(response);
  }
}
