import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'chat_room_screen.dart';
import 'contacts_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _searchQuery = '';
  List<DocumentSnapshot> _chatRooms = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get chat rooms from firebase
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('chat_rooms');

  @override
  void initState() {
    // // Request permission for iOS
    // if (Platform.isIOS) {
    //   _firebaseMessaging.requestPermission();
    // }
    super.initState();
    getData(); // Call the method to fetch data when the screen initializes
  }

  Future<void> getData() async {
    try {
      QuerySnapshot querySnapshot = await _collectionRef.get();
      _chatRooms = querySnapshot.docs; // Store chat room documents

      setState(() {}); // Update the UI with the fetched data
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching data: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
        data: CupertinoThemeData(
          brightness: MediaQuery.of(context).platformBrightness,
        ),
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Chats'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.add,
                ),
                onPressed: () {
                  _showModalBottomSheet(context);
                },
              ),
              onPressed: () {
                _showModalBottomSheet(context);
              },
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                // Handle the edit button press
                // Add your logic here
              },
            ),
          ),
          child: Center(
            child: ListView.builder(
              itemCount: _chatRooms.length,
              itemBuilder: (BuildContext context, int index) {
                String documentId = _chatRooms[index].id;

                // Extract the other user's ID from the document ID
                List<String> userIds = documentId.split('-');
                String otherUserId =
                    userIds.firstWhere((id) => id != _currentUserId);

                // Query the "users" collection for the other user's data
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(otherUserId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height - 100,
                        child: Container(
                          color: Colors
                              .transparent, // Set your desired background color here
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const Text('No data available');
                    }

                    // Extract name and photo from the retrieved data
                    String otherUserName =
                        snapshot.data?.get('name') ?? 'No Name';
                    String otherUserPhoto =
                        snapshot.data?.get('image') ?? 'No Image URL';

                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    contact: FavoriteUser(
                                      id: otherUserId,
                                      name: otherUserName,
                                      image: otherUserPhoto,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(otherUserPhoto),
                              ),
                              title: Text(
                                otherUserName,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          // Add a divider after each list item
                          color: Colors.grey,
                          height: 1,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ));
  }

  Color _getCustomColor(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    if (brightness == Brightness.dark) {
      // Return custom color for dark mode
      return const Color(0xFF1B1B1B);
    } else {
      // Return custom color for light mode
      return const Color(0xFFF9F9F9);
    }
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        final Color customColor = _getCustomColor(context);

        return FractionallySizedBox(
          heightFactor: 0.93,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: customColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        '',
                        style: TextStyle(),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'New Message',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                child: CupertinoSearchTextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<FavoriteUser>>(
                  future: _getFavorites(), // Call your function here
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CupertinoActivityIndicator(); // Display a loading indicator
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text(
                          'No favorite users found.'); // Handle no data scenario
                    } else {
                      return ListView.separated(
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Colors.grey,
                            height: 1,
                          );
                        },
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final favoriteUser = snapshot.data![index];
                          final itemTitle = favoriteUser.name;
                          final itemImage =
                              favoriteUser.image; // Get the image URL

                          if (_searchQuery.isNotEmpty &&
                              !itemTitle
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase())) {
                            return Container(); // Skip non-matching items
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    itemImage), // Load the user image
                              ),
                              title: Text(itemTitle),
                              onTap: () {
                                // Handle list item tap
                                // Add your logic here
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<List<FavoriteUser>> _getFavorites() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final userRef =
      FirebaseFirestore.instance.collection('users').doc(currentUser?.uid);
  final userSnapshot = await userRef.get();

  List<FavoriteUser> favorites = [];

  if (userSnapshot.exists) {
    final favoriteUserIds =
        List<String>.from(userSnapshot.data()?['favorite_users'] ?? []);
    debugPrint('Current User: ${currentUser?.uid}');
    // Fetch the image for each favorite user from the Firebase collection
    final List<DocumentSnapshot> userDocs = await Future.wait(
      favoriteUserIds.map(
        (userId) =>
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
      ),
    );

    // Create the FavoriteUser objects with the fetched image
    favorites = userDocs.map((doc) {
      final id = doc['id'].toString();
      final name = doc['name'];
      final image = doc['image'];
      final favoriteUser = FavoriteUser(id: id, name: name, image: image);
      return favoriteUser;
    }).toList();
  }

  return favorites;
}

class Contact {
  final String name;
  final String image;
  final String id;

  const Contact({
    required this.name,
    required this.image,
    required this.id,
  });
}
