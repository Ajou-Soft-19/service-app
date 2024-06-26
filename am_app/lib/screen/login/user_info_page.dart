import 'package:am_app/model/api/login_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/admin/auth_request.dart';
import 'package:am_app/screen/admin/monitor_page.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/login/edit_user_info_page.dart';
import 'package:am_app/screen/vehicle/vehicle_list_page.dart';
import 'package:am_app/screen/webview/webview.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserInfoPage(userProvider)),
    );
  }

  void onVehiclePressed(VehicleProvider vehicleProvider) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehicleListPage()),
    );
  }

  void onAuthorizationRequest(UserProvider userProvider) async {
    if (userProvider.hasRequestedEmergencyRole()) {
      Assets().showErrorSnackBar(context, 'Already requested Emergency Role');
      return;
    }

    try {
      int requestId = await LoginApi().requestEmergencyRole(userProvider);
      userProvider.setRequestedEmergencyRole(requestId);
      Assets().showSnackBar(context, 'Requested Emergency Role');
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
    }
  }

  void onAuthorizationRequestCheck(UserProvider userProvider) async {
    if (userProvider.hasRequestedEmergencyRole() == false) {
      Assets().showErrorSnackBar(context, 'No request for Emergency Role');
      return;
    }

    try {
      await LoginApi().checkRequestEmergencyRole(userProvider);
      userProvider.removeRequestedEmergencyRole();
      Assets().showSnackBar(context, 'Requested Emergency Role');
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
    }
  }

  void onMonitoringPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  void onAuthRequestPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthManagePagState()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final vehicleProvider = Provider.of<VehicleProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'User Info',
        backButton: true,
      ),
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
                  'Hello, $username',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _buildCarLicence(userProvider, vehicleProvider),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                _buildUserActions(userProvider, vehicleProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarLicence(
      UserProvider userProvider, VehicleProvider vehicleProvider) {
    if (!(userProvider.hasEmergencyRole() || userProvider.hasAdminRole())) {
      return const SizedBox();
    }
    return vehicleProvider.licenseNumber != null
        ? Text(
            'vechicle license: ${vehicleProvider.licenseNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          )
        : const Text(
            'Select your vechicle',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildUserActions(
      UserProvider userProvider, VehicleProvider vehicleProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildActionButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const WebViewPage())),
          backgroundColor: Colors.yellow,
          text: 'Ranking',
        ),
        userProvider.hasEmergencyRole()
            ? _buildActionButton(
                onPressed: () => onVehiclePressed(vehicleProvider),
                backgroundColor: Colors.indigo,
                text: 'Select Vehicle',
              )
            : userProvider.hasRequestedEmergencyRole()
                ? _buildActionButton(
                    onPressed: () => onAuthorizationRequestCheck(userProvider),
                    backgroundColor: Colors.orange,
                    text: 'Check Auth Request',
                  )
                : _buildActionButton(
                    onPressed: () => onAuthorizationRequest(userProvider),
                    backgroundColor: Colors.orange,
                    text: 'Request Emergency Auth',
                  ),
        userProvider.hasAdminRole()
            ? _buildActionButton(
                onPressed: () => onMonitoringPressed(),
                backgroundColor: Colors.indigo,
                text: 'Monitoring Page',
              )
            : const SizedBox(height: 0),
        userProvider.hasAdminRole()
            ? _buildActionButton(
                onPressed: () => onAuthRequestPressed(),
                backgroundColor: Colors.indigo,
                text: 'Admin Role Request Page',
              )
            : const SizedBox(height: 0),
        _buildActionButton(
          onPressed: () => onEditInfoPressed(userProvider),
          backgroundColor: Colors.blue,
          text: 'Edit Info',
        ),
        _buildActionButton(
          onPressed: () => onLogoutPressed(userProvider),
          backgroundColor: Colors.red[500]!,
          text: 'Logout',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Function() onPressed,
    required Color backgroundColor,
    required String text,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = screenWidth > 600 ? 600 : screenWidth * 0.8;

    return Column(
      children: [
        Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(30.0),
          color: backgroundColor,
          child: MaterialButton(
            minWidth: buttonWidth,
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
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
