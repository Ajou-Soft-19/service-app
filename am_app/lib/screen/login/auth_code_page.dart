import 'dart:async';

import 'package:am_app/model/api/email_verify_api.dart';
import 'package:am_app/model/api/login_api.dart';
import 'package:am_app/model/api/dto/jwt_token_info.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

class AuthCodePage extends StatefulWidget {
  const AuthCodePage(
      {Key? key,
      required this.loginType,
      required this.msg,
      required this.authString,
      required this.email})
      : super(key: key);

  final String loginType;
  final String msg;
  final String authString;
  final String email;

  @override
  State<AuthCodePage> createState() => _AuthCodePageState();
}

class _AuthCodePageState extends State<AuthCodePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";
  Color _errorMessageColor = Colors.red;
  final EmailVerifyApi _emailVerifyApi = EmailVerifyApi();

  void completeLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    JwtTokenInfo? tokenInfo;

    if (widget.loginType == "EMAIL_PW") {
      tokenInfo = await LoginApi().idpwLogin(widget.email, widget.authString);
    }

    Map<String, dynamic> accessTokenInfo =
        JwtDecoder.decode(tokenInfo!.accessToken!);

    await userProvider.setState(
        accessTokenInfo['username'],
        accessTokenInfo['sub'],
        accessTokenInfo['auth'],
        tokenInfo.accessToken,
        tokenInfo.refreshToken,
        false);
    Navigator.pop(context);
  }

  void onCodeSubmit() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool result =
          await _emailVerifyApi.authEmail(widget.email, _controller.text);
      if (!result) {
        _errorMessageColor = Colors.red;
        _errorMessage = "Wrong code. Please try again.";
      } else {
        completeLogin();
      }
    } on TimeoutException {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "Failed to connect to the server.";
      });
    } catch (e) {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "Failed to verify the code. Please try again.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void onResendCode() async {
    try {
      await _emailVerifyApi.resendAuthEmail(widget.email);
      setState(() {
        _errorMessageColor = Colors.blue;
        _errorMessage = "Auth code has been resent.";
      });
    } on TimeoutException {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "Failed to connect to the server.";
      });
    } catch (e) {
      setState(() {
        _errorMessageColor = Colors.red;
        _errorMessage = "Failed to resend the auth code. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              widget.msg,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const Text(
              'Auth Code',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 30,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                hintText: '• • • • • •',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                errorStyle: TextStyle(
                  color: _errorMessageColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLength: 6,
              onChanged: (value) {
                setState(() {
                  _errorMessage = "";
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: onCodeSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  backgroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onResendCode,
              child: const Text(
                'Resend Auth Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
