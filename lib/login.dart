import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tunnel/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'verification_code.dart';
import 'package:simple_animations/simple_animations.dart';

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // ignore: unused_field
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ignore: use_key_in_widget_constructors
  LoginPage({Key? key});

  Future<UserCredential?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithApple() async {
    return null;

    // Implement Apple sign-in method here using appropriate plugin
    // Similar to _signInWithGoogle() method
  }

  Future<UserCredential?> _signInWithPhone(BuildContext context) async {
    try {
      // ignore: no_leading_underscores_for_local_identifiers
      final FirebaseAuth _auth = FirebaseAuth.instance;

      // Replace the placeholder with the user's phone number
      String phoneNumber = '+38169630561';

      // Request to send an SMS verification code to the user's phone number
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval of the verification code on Android devices
          // You can directly sign in the user here if you want
          // Example: _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failure (e.g., invalid phone number)
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Save the verificationId and resendToken for later use
          // You'll need this when the user enters the received SMS code

          // Navigate to the EnterVerificationCodePage with the verificationId
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => verification_code(verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout, if any
          // Handle this if needed
        },
        timeout: const Duration(seconds: 60), // Timeout for code verification
      );
    } catch (e) {
      // Handle any errors that occur during the process
    }
    return null;
  }

  Future<void> _storeUserInfo(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Check if the user already exists in the database
    final userSnapshot = await userRef.get();
    if (userSnapshot.exists) {
      // User already exists, do not add a new user
      return;
    }

    // Get the FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();

    // User does not exist, add them to the database
    await userRef.set({
      'id': user.uid,
      'name': user.displayName,
      'image': user.photoURL,
      'favorite_users': [],
      'fcmToken': fcmToken, // Store the FCM token
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF4575F6),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF4575F6),
      ),
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDarkMode = theme.brightness == Brightness.dark;
          final textColor = isDarkMode ? Colors.white : Colors.black;
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/nautral_mode_backgroud.png'),
                  fit: BoxFit.cover),
            ),
            // color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  height: 0,
                ),
                Column(
                  children: [
                    Image.asset(
                      'assets/signal-svgrepo-com.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Welcome to Tunnel',
                      style: TextStyle(
                        fontSize: 24,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final UserCredential? userCredential =
                                  await _signInWithGoogle();
                              if (userCredential != null) {
                                final User user = userCredential.user!;
                                await _storeUserInfo(user);
                                // ignore: use_build_context_synchronously
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyApp(),
                                  ),
                                );
                              }
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Login Failed'),
                                  content: const Text(
                                      'An error occurred while logging in.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Column(children: [
                            Container(
                              width: 350,
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/google_icon.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final UserCredential? userCredential =
                                  await _signInWithApple();
                              if (userCredential != null) {
                                final User user = userCredential.user!;
                                await _storeUserInfo(user);
                                // ignore: use_build_context_synchronously
                                Navigator.pushReplacementNamed(
                                    context, '/main');
                              }
                            } catch (e) {
                              AlertDialog(
                                title: const Text('Login Failed'),
                                content: const Text(
                                    'An error occurred while logging in.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            }
                          },
                          child: Column(children: [
                            Container(
                              width: 350,
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/apple_icon.png',
                                    width: 22,
                                    height: 22,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Text(
                                    'Sign in with Apple',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final UserCredential? userCredential =
                                  await _signInWithPhone(context);
                              if (userCredential != null) {
                                final User user = userCredential.user!;
                                await _storeUserInfo(user);
                                // ignore: use_build_context_synchronously
                                Navigator.pushReplacementNamed(
                                    context, '/main');
                              }
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Login Failed'),
                                  content: const Text(
                                      'An error occurred while logging in.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Column(children: [
                            Container(
                              width: 350,
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/phone_icon.png',
                                    width: 22,
                                    height: 22,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Text(
                                    'Sign in with Phone',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
