import 'package:am_app/model/api/auth_request_api.dart';
import 'package:am_app/model/api/dto/auth_request_info.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AuthManagePagState extends StatefulWidget {
  const AuthManagePagState({super.key});

  @override
  State<AuthManagePagState> createState() => _AuthManagePagStateState();
}

class _AuthManagePagStateState extends State<AuthManagePagState> {
  final authRequestApi = AuthRequestApi();
  late List<AuthRequestInfo> displayAuthRequests;
  late List<AuthRequestInfo> originalAuthRequests;
  bool isLoading = false;
  bool isError = false;
  bool isPanelVisible = false;

  bool onlyPending = false;
  String emailFilter = '';
  final TextEditingController emailController = TextEditingController();
  Orientation? _originalOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _originalOrientation = MediaQuery.of(context).orientation;
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    emailController.addListener(() {
      setState(() {
        emailFilter = emailController.text;
      });
    });
    loadAuthRequests();
  }

  @override
  void dispose() {
    if (_originalOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadAuthRequests() async {
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });

    try {
      originalAuthRequests =
          await authRequestApi.getAuthRequestInfo(userProvider);
      filterAuthRequest();
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
      setState(() {
        isError = true;
      });
    }

    if (!isError) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onApproveButtonPressed(
      UserProvider userProvider, int authRequestId) async {
    try {
      await authRequestApi.approveAuthRequest(userProvider, authRequestId);

      // 배열에서 해당 요청을 찾아서 상태를 업데이트합니다.
      final index = displayAuthRequests.indexWhere(
          (authRequest) => authRequest.authRequestId == authRequestId);
      if (index != -1) {
        setState(() {
          displayAuthRequests[index].isApproved = true;
          displayAuthRequests[index].isPending = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to approve auth request: $e');
      Assets().showErrorSnackBar(context, e.toString());
    }
  }

  void onRejectButtonPressed(
      UserProvider userProvider, int authRequestId) async {
    try {
      await authRequestApi.rejectAuthRequest(userProvider, authRequestId);

      // 배열에서 해당 요청을 찾아서 상태를 업데이트합니다.
      final index = displayAuthRequests.indexWhere(
          (authRequest) => authRequest.authRequestId == authRequestId);
      if (index != -1) {
        setState(() {
          displayAuthRequests[index].isApproved = false;
          displayAuthRequests[index].isPending = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to reject auth request: $e');
      Assets().showErrorSnackBar(context, e.toString());
    }
  }

  void resetFilter() {
    setState(() {
      onlyPending = false;
      emailFilter = '';
      emailController.clear();
    });
  }

  void filterAuthRequest() async {
    setState(() {
      displayAuthRequests = originalAuthRequests
          .where((authRequest) =>
              (onlyPending ? authRequest.isPending : true) &&
              (emailFilter.isNotEmpty
                  ? authRequest.email.contains(emailFilter)
                  : true))
          .toList();
    });
  }

  void togglePanelVisibility() {
    setState(() {
      isPanelVisible = !isPanelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _buildAppBar(userProvider),
      body: Stack(
        children: [
          isError
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 40.0),
                      SizedBox(height: 10.0),
                      Text(
                          'An error occurred while loading. Please try again.'),
                    ],
                  ),
                )
              : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAuthRequestList(userProvider),
          if (isPanelVisible)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: screenWidth * 0.3,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: _buildFilterPanel(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              title:
                  Text('Filter', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Search Email', // 줄바꿈을 제거합니다.
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    emailFilter = value;
                  });
                  filterAuthRequest();
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Search Pending',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: ElevatedButton(
                onPressed: () {
                  onlyPending = !onlyPending;
                  filterAuthRequest();
                }, // 텍스트를 흰색으로 설정합니다.
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.indigo),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  )),
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0)),
                  textStyle:
                      MaterialStateProperty.all(const TextStyle(fontSize: 20)),
                  elevation: MaterialStateProperty.all(5),
                ),
                child: Text(onlyPending ? 'Only Pending' : 'Search All',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        )),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0)),
                        textStyle: MaterialStateProperty.all(
                            const TextStyle(fontSize: 20)),
                        elevation: MaterialStateProperty.all(5),
                      ),
                      onPressed: () {
                        resetFilter();
                        filterAuthRequest();
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserProvider userProvider) {
    return AppBar(
      backgroundColor: Colors.indigo,
      title: const Text(
        'Admin Role Request List Page',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        MaterialButton(
          onPressed: loadAuthRequests,
          minWidth: 60.0,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(width: 30.0),
        MaterialButton(
            onPressed: togglePanelVisibility,
            minWidth: 60.0,
            child: Icon(
                isPanelVisible ? Icons.close : Icons.filter_list_rounded,
                color: Colors.white)),
        const SizedBox(width: 50.0),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Widget _buildAuthRequestList(UserProvider userProvider) {
    ThemeData themeData = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: DataTable(
            columns: [
              DataColumn(
                label: SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      'ID',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 150,
                  child: Center(
                    child: Text(
                      'Email',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 160,
                  child: Center(
                    child: Text(
                      'Role',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      'Approved',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 180,
                  child: Center(
                    child: Text(
                      'Modified Date',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 250,
                  child: Center(
                    child: Text(
                      'Action',
                      style: TextStyle(color: themeData.colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
            rows: displayAuthRequests.map((authRequest) {
              return DataRow(cells: [
                DataCell(Text(
                  authRequest.authRequestId.toString(),
                  style: const TextStyle(fontSize: 18),
                )),
                DataCell(Text(
                  authRequest.email,
                  style: const TextStyle(fontSize: 18),
                )),
                DataCell(Text(
                  authRequest.role.replaceFirst('ROLE_', ''),
                  style: const TextStyle(fontSize: 18),
                )),
                DataCell(
                  Center(
                    child: authRequest.isPending
                        ? Container() // isPending이 true일 경우 아무것도 표시하지 않습니다.
                        : Icon(
                            authRequest.isApproved
                                ? Icons.check_box
                                : Icons.cancel,
                            color: authRequest.isApproved
                                ? Colors.blue
                                : Colors.red,
                          ),
                  ),
                ),
                DataCell(Text(
                  _formatDate(DateTime.parse(authRequest.modifiedDate)),
                  style: const TextStyle(fontSize: 18),
                )),
                DataCell(
                  authRequest.isPending
                      ? Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () => onApproveButtonPressed(
                                    userProvider, authRequest.authRequestId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ), // 아직 정의되지 않은 함수
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () => onRejectButtonPressed(
                                    userProvider, authRequest.authRequestId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ), // 아직 정의되지 않은 함수
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: SizedBox(
                            width: 120,
                            child: OutlinedButton(
                              onPressed: () {},

                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ), // 아직 정의되지 않은 함수
                              child: Text(
                                'Processed',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                          ),
                        ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
