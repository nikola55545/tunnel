// ignore_for_file: deprecated_member_use

import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';
import 'contacts_screen.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData.light().copyWith(
        bottomAppBarColor: const Color(0xFFF9F9F9),
      ),
      darkTheme: ThemeData.dark().copyWith(
        bottomAppBarColor: const Color(0xFF1B1B1B),
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder<User?>(
        future: _auth.authStateChanges().first,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasData) {
              return const MyHomePage();
            } else {
              return LoginPage();
            }
          }
        },
      ),
      routes: {
        '/main': (context) => const MyHomePage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const ContactsScreen(),
    const ChatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: MediaQuery.of(context).platformBrightness,
      ),
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: BottomNavyBar(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          showElevation: false,
          curve: Curves.easeInOut,
          selectedIndex: _currentIndex,
          onItemSelected: _onItemTapped,
          items: [
            BottomNavyBarItem(
              icon: const Icon(CupertinoIcons.person_2),
              title: const Text('Contacts'),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
              textAlign: TextAlign.center,
            ),
            BottomNavyBarItem(
              icon: const Icon(CupertinoIcons.chat_bubble),
              title: const Text('Chats'),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
              textAlign: TextAlign.center,
            ),
            BottomNavyBarItem(
              icon: const Icon(CupertinoIcons.settings),
              title: const Text('Settings'),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
