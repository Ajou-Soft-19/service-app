import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/login/login_page.dart';
import 'package:am_app/screen/login/user_info_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.username == null) {
      return const LoginPage();
    } else {
      return const UserInfoPage();
    }
  }
}
