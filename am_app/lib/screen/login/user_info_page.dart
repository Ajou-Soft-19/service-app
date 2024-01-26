import 'package:am_app/model/api/login_api.dart';
import 'package:am_app/model/api/user_info_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String username = '';
  String email = '';
  String userProfileImgUrl = 'assets/placeholder.png';
  bool hasProfileImage = false;

  @override
  void initState() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    super.initState();
    username =
        userProvider.username != null ? userProvider.username! : username;
    email = userProvider.email != null ? userProvider.email! : email;
    if (userProvider.profileImageUrl != null) {
      userProfileImgUrl = userProvider.profileImageUrl!;
      hasProfileImage = true;
    }
  }

  void onLogoutPressed(UserProvider userProvider) async {
    try {
      LoginApi().logout();
    } catch (e) {}
    userProvider.deleteState(false);
  }

  void onEditInfoPressed(UserProvider userProvider) async {
    final TextEditingController usernameEditingController =
        TextEditingController();

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    RoundedRectangleBorder customRoundedRectangleBorder =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));

    Map<String, dynamic>? editedValues = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return Dialog(
            shape: customRoundedRectangleBorder,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '유저 정보 수정',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: usernameEditingController,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        hintText: username,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (value) {
                        formKey.currentState!.validate();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        } else if (value.length > 10) {
                          return '닉네임은 10 글자보다 작아야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              String newUsername =
                                  usernameEditingController.text;
                              Navigator.pop(context, {'username': newUsername});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 35, vertical: 15),
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('저장'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 35, vertical: 15),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          child: const Text('취소'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });

    if (editedValues != null && editedValues.isNotEmpty) {
      try {
        await UserInfoApi()
            .editUsername(userProvider, editedValues['username']);
        setState(() {
          username = editedValues['username'];
        });
      } catch (e) {
        return Assets().showErrorSnackBar(context, "회원 이름 업데이트에 실패했습니다.");
      }
    }
  }

  void onVehiclePressed() async {
    Assets().showErrorSnackBar(context, "기능 준비 중입니다.");
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildProfileImage(),
                const SizedBox(height: 10),
                Text(
                  'Hello, $username\ncar license: 12341234',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                _buildUserActions(userProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ClipOval buildProfileImage() {
    return ClipOval(
      child: hasProfileImage
          ? Image.network(
              userProfileImgUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            )
          : Image.asset(
              userProfileImgUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
    );
  }

  Widget _buildUserActions(UserProvider userProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildActionButton(
          onPressed: () => onVehiclePressed(),
          backgroundColor: Colors.indigo,
          text: '차량 등록 및 변경',
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          onPressed: () => onEditInfoPressed(userProvider),
          backgroundColor: Colors.blue,
          text: '닉네임 수정',
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          onPressed: () => onLogoutPressed(userProvider),
          backgroundColor: Colors.red[500]!,
          text: '로그아웃',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Function() onPressed,
    required Color backgroundColor,
    required String text,
  }) {
    return Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: backgroundColor,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
