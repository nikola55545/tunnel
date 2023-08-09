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
                ],
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  CupertinoButton(
                    child: const Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
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
