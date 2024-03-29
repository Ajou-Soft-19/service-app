import 'package:am_app/model/api/user_info_api.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  late FocusNode emailFocusNode;
  late FocusNode phoneNumberFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    emailFocusNode = FocusNode();
    phoneNumberFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    phoneNumberFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<bool> onCreatAccountPressed() async {
    try {
      await UserInfoApi().createAccount(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
          _phoneNumberController.text);
      return true;
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
      return false;
    }
  }

  InputDecoration _buildModernInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      errorStyle: const TextStyle(color: Colors.red),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Account', backButton: true),
      body: Center(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(emailFocusNode);
                        },
                        controller: _usernameController,
                        decoration: _buildModernInputDecoration('Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        focusNode: emailFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(phoneNumberFocusNode);
                        },
                        controller: _emailController,
                        decoration: _buildModernInputDecoration('Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email';
                          } else if (!_emailRegex.hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        focusNode: phoneNumberFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(passwordFocusNode);
                        },
                        controller: _phoneNumberController,
                        decoration: _buildModernInputDecoration('Phone Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        focusNode: passwordFocusNode,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(confirmPasswordFocusNode);
                        },
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _buildModernInputDecoration('Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter password more than 8 characters';
                          }
                          if (value.length < 8) {
                            return 'Enter password more than 8 characters';
                          } else if (!_passwordRegex.hasMatch(value)) {
                            return "Need one letter, number, and special character each";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        focusNode: confirmPasswordFocusNode,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration:
                            _buildModernInputDecoration('Confirm Password'),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Password does not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    try {
                                      final result =
                                          await onCreatAccountPressed();
                                      if (!result) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        return;
                                      }
                                      Navigator.pop(context);
                                      Assets().showPopup(context,
                                          'Account created successfully. Please log in.');
                                    } catch (e) {
                                      Assets().showPopup(context,
                                          'Account creation failed. Please try again.');
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.blue,
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
