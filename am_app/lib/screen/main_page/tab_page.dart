import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/login/login_page.dart';
import 'package:am_app/screen/login/user_info_page.dart';
import 'package:am_app/screen/map/map_page.dart';
import 'package:am_app/screen/webview/webview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabPage extends StatefulWidget {
  const TabPage({Key? key}) : super(key: key);

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> with SingleTickerProviderStateMixin {
  final List<Tab> _tabs = [
    const Tab(
      icon: Icon(Icons.map, size: 23),
      iconMargin: EdgeInsets.zero,
      child: Text('Map', style: TextStyle(fontSize: 15)),
    ),
    const Tab(
      icon: Icon(Icons.person, size: 23),
      iconMargin: EdgeInsets.zero,
      child: Text('Account', style: TextStyle(fontSize: 15)),
    ),
    const Tab(
      icon: Icon(Icons.grade, size: 23),
      iconMargin: EdgeInsets.zero,
      child: Text('Ranking', style: TextStyle(fontSize: 15)),
    ),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.username == null) {
        _tabController.index = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: [
          userProvider.hasEmergencyRole() ? const MapPage() : const MapPage(),
          userProvider.username != null
              ? const UserInfoPage()
              : const LoginPage(),
          const WebViewPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.blue.shade200),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        tabs: _tabs
                            .map((tab) => SizedBox(
                                  width: double.infinity,
                                  height: kToolbarHeight,
                                  child: tab,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              });
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
