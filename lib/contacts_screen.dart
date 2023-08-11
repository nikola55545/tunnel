import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'chat_room_screen.dart';

class FavoriteUser {
  final String id;
  final String name;
  final String image;

  FavoriteUser({required this.id, required this.name, required this.image});
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  List<FavoriteUser> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getFavorites().then((value) {
      setState(() {
        favorites = value;
        isLoading = false; // Set isLoading to false when favorites are fetched
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Contacts'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(CupertinoIcons.add),
              onPressed: () {
                _showModalBottomSheet(context);
              },
            ),
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
      child: Column(
        children: [
          Expanded(
            child: Material(
              color: _getCustomColor(context) == Colors.black
                  ? Colors.black
                  : Colors.white,
              child: isLoading
                  ? const Center(
                      child:
                          CupertinoActivityIndicator(), // Show loader while favorites are loading
                    )
                  : ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(
                          color: Colors.grey,
                          height: 1,
                        );
                      },
                      itemCount: favorites.length,
                      itemBuilder: (BuildContext context, int index) {
                        final favorite = favorites[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(favorite.image),
                          ),
                          title: Text(favorite.name),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  contact: FavoriteUser(
                                    id: favorite.id,
                                    name: favorite.name,
                                    image: favorite.image,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
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

  void _saveFavorites(List<FavoriteUser> favorites) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser?.uid);

    final favoriteUserIds = favorites.map((favorite) => favorite.id).toList();
    await userRef.update({
      'favorite_users': favoriteUserIds,
    });
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
                        'New Contact',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(),
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
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      final List<QueryDocumentSnapshot> users =
                          snapshot.data?.docs ?? [];

                      final List<QueryDocumentSnapshot> filteredUsers = users
                          .where((user) => user['name']
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                      final currentUser = FirebaseAuth.instance.currentUser;
                      final currentUserId = currentUser?.uid;

                      return ListView.separated(
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Colors.grey,
                            height: 1,
                          );
                        },
                        itemCount: filteredUsers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final user = filteredUsers[index];
                          final String id = user['id'];
                          final String itemTitle = user['name'];
                          final String itemImage = user['image'];

                          // Exclude the current user from the list
                          if (id != currentUserId) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(itemImage),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(itemTitle),
                                    if (!favorites.any((favorite) =>
                                        favorite.id == id.toString()))
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            favorites.add(FavoriteUser(
                                              id: id.toString(),
                                              name: itemTitle,
                                              image: itemImage,
                                            ));
                                            _saveFavorites(favorites);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  // Handle list item tap
                                  // Add your logic here
                                },
                              ),
                            );
                          } else {
                            return const SizedBox
                                .shrink(); // Skip current user's data
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }
}
