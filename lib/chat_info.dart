import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'contacts_screen.dart';

class ChatInfoScreen extends StatelessWidget {
  final FavoriteUser contact;

  const ChatInfoScreen({Key? key, required this.contact}) : super(key: key);

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
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'User Info',
          style: TextStyle(
            color: middleTextColor,
          ),
        ),
        backgroundColor: navigationBarBackgroundColor,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(contact.image),
              ),
              const SizedBox(height: 20),
              Text(
                contact.name,
                style: textStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // iOS-style List with options
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
                                  color: Colors.blue, // Set your desired color
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
                                color: Colors.purple, // Set your desired color
                                borderRadius: BorderRadius.circular(
                                    8), // Set your desired radius
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons
                                      .music_note_2, // Set your desired icon
                                  color: Colors
                                      .white, // Set your desired icon color
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 16), // Add spacing between icon and text
                            Text(
                              "Notifications",
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
                                  color: Colors.red, // Set your desired color
                                  borderRadius: BorderRadius.circular(
                                      8), // Set your desired radius
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons
                                        .person_crop_circle_badge_xmark, // Set your desired icon
                                    color: Colors
                                        .white, // Set your desired icon color
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      16), // Add spacing between icon and text
                              const Text(
                                "Block",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () {
                            //alert dialog
                            showCupertinoDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  CupertinoAlertDialog(
                                title: const Text('Block User'),
                                content: const Text(
                                    'Are you sure you want to block this user?'),
                                actions: <Widget>[
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  CupertinoDialogAction(
                                    child: const Text('Block'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
