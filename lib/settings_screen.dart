import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const SettingsScreen({Key? key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = false;

  Future<void> _signOut() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      // Sign out from Firebase Authentication
      await auth.signOut();

      // Sign out from Google Sign-In
      await googleSignIn.signOut();
    } catch (e) {
      // Handle sign out errors
      // ignore: avoid_print
      print('Error signing out: $e');
    }
  }

  late User currentUser;
  late String userImage = "";
  late String userName = "";

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = currentUser.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    setState(() {
      userImage = userData?['image'] ?? '';
      userName = userData?['name'] ?? '';
    });
  }

  Future<void> _uploadImageAndSaveUrl(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${currentUser.uid}.jpg');
      final uploadTask = storageRef.putFile(image);
      await uploadTask.whenComplete(() {});
      final imageURL = await storageRef.getDownloadURL();

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      await userRef.update({'image': imageURL});
      setState(() {
        userImage = imageURL;
      });
    } catch (e) {
      print('Error uploading image and saving URL: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _uploadImageAndSaveUrl(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    final navigationBarBackgroundColor =
        isDarkMode ? const Color(0xFF1B1B1B) : Colors.white;
    final backgroundColor = isDarkMode ? Colors.black : Color(0xffF8F8F8);
    final middleTextColor = isDarkMode ? Colors.white : Colors.black;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    TextStyle textStyle = TextStyle(
      fontSize: 20,
      decoration: TextDecoration.none,
      color: middleTextColor,
      fontWeight: FontWeight.normal,
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationZ(
                180 * 3.1415927 / 180), // 180 degrees in radians
            child: IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_left),
              color: Colors.red,
              onPressed: () {
                _signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
          onPressed: () {
            _signOut();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          _pickImage();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            color: Theme.of(context).primaryColor,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Show loading circle when isLoading is true
                                if (isLoading)
                                  const CupertinoActivityIndicator(),
                                // Show user image if available
                                if (!isLoading && userImage.isNotEmpty)
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(userImage),
                                    radius: 50,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 1),
                            width: 100,
                            color: Colors.black.withOpacity(0.5),
                            child: const Text(
                              "Edit",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.5,
                    child: Text(
                      currentUser.email != null
                          ? currentUser.email!
                          : 'email@example.com', // Default email
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: CupertinoListTile(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              backgroundColor:
                                  isDarkMode ? Color(0xFF1B1B1B) : Colors.white,
                              title: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.blue, // Set your desired color
                                      borderRadius: BorderRadius.circular(
                                          8), // Set your desired radius
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons
                                            .bell, // Set your desired icon
                                        color: Colors
                                            .white, // Set your desired icon color
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          16), // Add spacing between icon and text
                                  Text(
                                    "Notifications",
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                              trailing: CupertinoSwitch(
                                value: true, // Change to your switch value
                                onChanged: (bool value) {
                                  // Handle switch change
                                },
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          CupertinoListTile(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              backgroundColor:
                                  isDarkMode ? Color(0xFF1B1B1B) : Colors.white,
                              title: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .green, // Set your desired color
                                      borderRadius: BorderRadius.circular(
                                          8), // Set your desired radius
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons
                                            .rays, // Set your desired icon
                                        color: Colors
                                            .white, // Set your desired icon color
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          16), // Add spacing between icon and text
                                  Text(
                                    "Vibrations",
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                              trailing: CupertinoSwitch(
                                value: true, // Change to your switch value
                                onChanged: (bool value) {
                                  // Handle switch change
                                },
                              )),
                          const Divider(height: 1),
                          CupertinoListTile(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            backgroundColor:
                                isDarkMode ? Color(0xFF1B1B1B) : Colors.white,
                            title: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange, // Set your desired color
                                    borderRadius: BorderRadius.circular(
                                        8), // Set your desired radius
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons
                                          .person, // Set your desired icon
                                      color: Colors
                                          .white, // Set your desired icon color
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        16), // Add spacing between icon and text
                                Text(
                                  "Account Settings",
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                            trailing: const Icon(CupertinoIcons.right_chevron),
                            onTap: () {
                              // Handle option 2 tap
                            },
                          ),
                          const Divider(
                            height: 1,
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: CupertinoListTile(
                              backgroundColor:
                                  isDarkMode ? Color(0xFF1B1B1B) : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              title: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red, // Set your desired color
                                      borderRadius: BorderRadius.circular(
                                          8), // Set your desired radius
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons
                                            .question, // Set your desired icon
                                        color: Colors
                                            .white, // Set your desired icon color
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          16), // Add spacing between icon and text
                                  const Text(
                                    "Placeholder",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Handle option 3 tap
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      //show alert dialog, if yes delete account and logout, if no do nothing
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                                'Are you sure you want to delete your account?'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('No'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoDialogAction(
                                child: const Text('Yes'),
                                onPressed: () async {
                                  //delete account
                                  await currentUser.delete();
                                  //delete from users collection
                                  final userRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser.uid);
                                  await userRef.delete();
                                  //logout
                                  _signOut();
                                  // ignore: use_build_context_synchronously
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
