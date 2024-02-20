import 'package:am_app/model/api/user_info_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:flutter/material.dart';

class EditUserInfoPage extends StatefulWidget {
  final UserProvider userProvider;

  const EditUserInfoPage(this.userProvider, {Key? key}) : super(key: key);

  @override
  _EditUserInfoPageState createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    usernameEditingController.text = widget.userProvider.username!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit User Info',
        backButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameEditingController,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  hintText: widget.userProvider.username,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    return 'Please enter your nickname.';
                  } else if (value.length > 10) {
                    return 'Nickname must be less than 10 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String newUsername = usernameEditingController.text;
                    try {
                      await UserInfoApi()
                          .editUsername(widget.userProvider, newUsername);
                      setState(() {
                        widget.userProvider.updateUsername(newUsername);
                      });
                    } catch (e) {
                      return Assets().showErrorSnackBar(
                          context, "Failed to update username.");
                    }
                  }
                },
                child: const Text('save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
