import 'dart:convert';

class ApiResponse {
  final String httpStatus;
  final int code;
  final Map<String, dynamic> data;

  ApiResponse(
      {required this.httpStatus, required this.code, required this.data});

  factory ApiResponse.fromJson(String str) =>
      ApiResponse.fromMap(json.decode(str));

  factory ApiResponse.fromMap(Map<String, dynamic> json) => ApiResponse(
        httpStatus: json["httpStatus"],
        code: json["code"],
        data: json["data"],
      );
}
