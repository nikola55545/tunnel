import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// ignore: unnecessary_import
import 'package:flutter/rendering.dart';
// import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:image_picker/image_picker.dart';
import 'contacts_screen.dart';
import 'package:bubble/bubble.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'chat_info.dart';

class ChatPage extends StatefulWidget {
  final FavoriteUser contact;

  const ChatPage({super.key, required this.contact});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isNewMessageArrived = false;
  late ScrollController _scrollController;
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  // ignore: unused_field
  late Stream<List<types.Message>> _messagesStream;
  final List<types.Message> _messages = [
    // Add more messages here
  ];

  Future<void> _playSendMessageSound() async {
    await _audioPlayer.play(AssetSource('send.wav'));
  }

  Future<void> _playReceiveMessageSound() async {
    await _audioPlayer.play(AssetSource('get.wav'));
  }

  // ignore: unused_element
  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _bubbleBuilder(
    Widget child, {
    required types.Message message,
    required dynamic nextMessageInGroup,
  }) {
    bool isImageMessage = message is types.ImageMessage;

    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(
        message.createdAt ?? DateTime.now().millisecondsSinceEpoch);
    final String timestamp = DateFormat('H:mm').format(messageTime);

    bool isCurrentUser = message.author.id == currentUserId;
    bool isDarkMode = getCustomColor(context) == Colors.black;

    Color bubbleColor = isCurrentUser
        ? const Color(0xff0075FB)
        : isDarkMode
            ? const Color.fromARGB(255, 82, 82, 82)
            : const Color(0xffE6E6E8);

    Color textColor = isCurrentUser
        ? CupertinoColors.white
        : isDarkMode
            ? Colors.white
            : const Color.fromARGB(255, 159, 159, 159);

    // Apply different styles for image messages
    if (isImageMessage) {
      bubbleColor = Colors.transparent;
      textColor = isCurrentUser
          ? CupertinoColors.white
          : isDarkMode
              ? Colors.white
              : const Color.fromARGB(255, 109, 109, 109);
    }

    // Create a rounded container for the image
    Widget imageWidget = child;
    if (isImageMessage) {
      imageWidget = Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(10), // Adjust the radius as needed
          color: bubbleColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }

    return Bubble(
      radius: const Radius.circular(10),
      padding: const BubbleEdges.only(top: 2, bottom: 8, left: 4, right: 8),
      elevation: 0,
      color: bubbleColor,
      margin: nextMessageInGroup != null &&
              nextMessageInGroup is bool &&
              nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 6)
          : null,
      nip: nextMessageInGroup != null &&
              nextMessageInGroup is bool &&
              nextMessageInGroup
          ? BubbleNip.no
          : isCurrentUser
              ? BubbleNip.rightBottom
              : BubbleNip.leftBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          imageWidget, // Use the modified image widget
          const SizedBox(height: 0),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendPressed(types.PartialText message) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final selectedUserId = widget.contact.id;

    final chatRoomName1 = '$currentUserId-$selectedUserId';
    final chatRoomName2 = '$selectedUserId-$currentUserId';

    final newMessage = types.TextMessage(
      author: types.User(
        id: currentUserId.toString(),
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: UniqueKey().toString(),
      text: message.text,
    );

    try {
      // Initialize Firebase if not already initialized
      await Firebase.initializeApp();

      final chatRoomRef1 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName1);
      final chatRoomRef2 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName2);

      // Use batch write to update the appropriate chat room
      final batch = FirebaseFirestore.instance.batch();

      // Set the new message in the correct chat room
      if ((await chatRoomRef1.get()).exists) {
        batch.set(
          chatRoomRef1.collection('messages').doc(newMessage.id),
          {
            'author_id': currentUserId,
            'text': message.text,
            'created_at': FieldValue.serverTimestamp(),
          },
        );
      } else if ((await chatRoomRef2.get()).exists) {
        batch.set(
          chatRoomRef2.collection('messages').doc(newMessage.id),
          {
            'author_id': currentUserId,
            'text': message.text,
            'created_at': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      // Add the new message to the _messages list
      setState(() {
        _messages.add(newMessage);
        _isNewMessageArrived = false;
      });
      await _playSendMessageSound();
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMessages(); // Call the function to load previous messages
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    try {
      await Firebase
          .initializeApp(); // Initialize Firebase if not already initialized

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final selectedUserId = widget.contact.id;

      final chatRoomName1 = '$currentUserId-$selectedUserId';
      final chatRoomName2 = '$selectedUserId-$currentUserId';

      final chatRoomRef1 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName1);
      final chatRoomRef2 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName2);

      CollectionReference messagesCollection;
      Stream<QuerySnapshot> messagesStream;

      if ((await chatRoomRef1.get()).exists) {
        messagesCollection = chatRoomRef1.collection('messages');
      } else {
        messagesCollection = chatRoomRef2.collection('messages');
      }

      messagesStream = messagesCollection
          .orderBy('created_at', descending: true)
          .snapshots();

      messagesStream.listen((querySnapshot) {
        final messages = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final authorId = data['author_id'] as String?;
              final createdAt =
                  (data['created_at'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0;
              final text = data['text'] as String?;
              final imageUri = data['image_uri'] as String?;

              if (text != null) {
                return types.TextMessage(
                  author: types.User(
                    id: authorId ?? '',
                  ),
                  createdAt: createdAt,
                  id: doc.id,
                  text: text,
                );
              } else if (imageUri != null) {
                return types.ImageMessage(
                  name: 'Photo',
                  size: 1,
                  author: types.User(
                    id: authorId ?? '',
                  ),
                  createdAt: createdAt,
                  id: doc.id,
                  uri: imageUri,
                );
              }

              return null;
            })
            .whereType<types.Message>()
            .toList();

        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          if (_messages.isNotEmpty &&
              _messages.first.author.id != currentUserId) {
            _isNewMessageArrived = true;
            _playReceiveMessageSound();
          }
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading messages: $e');
      }
    }
  }

  Color getCustomColor(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    if (brightness == Brightness.dark) {
      return Colors.black; // Dark mode color
    } else {
      return const Color(0xFFF9F9F9); // Light mode color
    }
  }

  // ignore: unused_element
  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleImageSelection() async {
    try {
      final result = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.gallery,
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        final image = await decodeImageFromList(bytes);

        final currentUserId =
            FirebaseAuth.instance.currentUser!.uid; // Retrieve currentUserId

        final newImageMessage = types.ImageMessage(
          author: types.User(
            id: currentUserId,
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height?.toDouble() ??
              0, // Provide a default value of 0 if null
          id: UniqueKey().toString(),
          name: result.name,
          size: bytes.length,
          uri:
              '', // Initialize uri to an empty string, will be updated after upload
          width: image.width?.toDouble() ??
              0, // Provide a default value of 0 if null
        );

        // Upload the image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child('${newImageMessage.id}.jpg');
        final uploadTask = storageRef.putData(Uint8List.fromList(bytes));

        // Listen to the upload task completion
        await uploadTask.whenComplete(() async {
          final downloadUrl = await storageRef.getDownloadURL();

          // Update the image message with the download URL
          final updatedImageMessage =
              newImageMessage.copyWith(uri: downloadUrl);

          // Add the image message to the messages collection in Firestore
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final selectedUserId = widget.contact.id;

          final chatRoomName1 = '$currentUserId-$selectedUserId';
          final chatRoomName2 = '$selectedUserId-$currentUserId';

          final chatRoomRef1 = FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomName1);
          final chatRoomRef2 = FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomName2);

          final messagesCollection = (await chatRoomRef1.get()).exists
              ? chatRoomRef1.collection('messages')
              : chatRoomRef2.collection('messages');

          await messagesCollection.add({
            'author_id': currentUserId,
            'text': null, // Since it's an image message, text can be null
            'created_at': FieldValue.serverTimestamp(),
            'image_uri': downloadUrl, // Store the image URI
          });

          // You might want to call _loadMessages() here to refresh the messages

          setState(() {
            _messages.add(newImageMessage);
            _isNewMessageArrived = false;
          });
        });
      } else {
        print("result is null");
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _handleCameraSelection() async {
    try {
      final result = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.camera,
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        final image = await decodeImageFromList(bytes);

        final currentUserId =
            FirebaseAuth.instance.currentUser!.uid; // Retrieve currentUserId

        final newImageMessage = types.ImageMessage(
          author: types.User(
            id: currentUserId,
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height?.toDouble() ??
              0, // Provide a default value of 0 if null
          id: UniqueKey().toString(),
          name: result.name,
          size: bytes.length,
          uri:
              '', // Initialize uri to an empty string, will be updated after upload
          width: image.width?.toDouble() ??
              0, // Provide a default value of 0 if null
        );

        // Upload the image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child('${newImageMessage.id}.jpg');
        final uploadTask = storageRef.putData(Uint8List.fromList(bytes));

        // Listen to the upload task completion
        await uploadTask.whenComplete(() async {
          final downloadUrl = await storageRef.getDownloadURL();

          // Update the image message with the download URL
          final updatedImageMessage =
              newImageMessage.copyWith(uri: downloadUrl);

          // Add the image message to the messages collection in Firestore
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final selectedUserId = widget.contact.id;

          final chatRoomName1 = '$currentUserId-$selectedUserId';
          final chatRoomName2 = '$selectedUserId-$currentUserId';

          final chatRoomRef1 = FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomName1);
          final chatRoomRef2 = FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomName2);

          final messagesCollection = (await chatRoomRef1.get()).exists
              ? chatRoomRef1.collection('messages')
              : chatRoomRef2.collection('messages');

          await messagesCollection.add({
            'author_id': currentUserId,
            'text': null, // Since it's an image message, text can be null
            'created_at': FieldValue.serverTimestamp(),
            'image_uri': downloadUrl, // Store the image URI
          });

          // You might want to call _loadMessages() here to refresh the messages

          setState(() {
            _messages.add(newImageMessage);
            _isNewMessageArrived = false;
          });
        });
      } else {
        print("result is null");
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _handleAttachmentPressed() {
    final bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
            color: isDarkMode ? const Color(0xFF1B1B1B) : Colors.white,
          ),
          child: SizedBox(
            height: 170,
            child: Column(
              children: [
                const Text("Share", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _handleImageSelection();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded corners
                              color: CupertinoColors.systemBlue,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 16), // Add spacing between text and circle
                        const Text('Photo', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _handleCameraSelection();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded corners
                              color: CupertinoColors.systemGreen,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.camera,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 16), // Add spacing between text and circle
                        const Text('Camera', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            // _handleCameraSelection();
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded corners
                              color: CupertinoColors.systemOrange,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.doc,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 16), // Add spacing between text and circle
                        const Text('Document', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded corners
                              color: CupertinoColors.systemRed,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.map_pin_ellipse,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 16), // Add spacing between text and circle
                        const Text('Location', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = getCustomColor(context) == Colors.black;

    if (_isNewMessageArrived) {
      try {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {}
    }

    TextStyle generateReceivedMessageBodyTextStyle() {
      return TextStyle(
        decoration: TextDecoration.none,
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );
    }

    final theme = DefaultChatTheme(
        sentMessageBodyLinkTextStyle: const TextStyle(
            decoration: TextDecoration.underline,
            color: CupertinoColors.white,
            decorationColor: CupertinoColors.white,
            decorationStyle: TextDecorationStyle.solid,
            fontWeight: FontWeight.normal),
        receivedMessageBodyLinkTextStyle: const TextStyle(
            decoration: TextDecoration.underline,
            color: CupertinoColors.black,
            decorationColor: CupertinoColors.black,
            decorationStyle: TextDecorationStyle.solid,
            fontWeight: FontWeight.normal),
        backgroundColor: getCustomColor(context),
        inputBackgroundColor: getCustomColor(context) == Colors.black
            ? const Color(0xFF1B1B1B)
            : CupertinoColors.white,
        inputTextColor: getCustomColor(context) == Colors.black
            ? CupertinoColors.white
            : CupertinoColors.black,
        inputContainerDecoration: BoxDecoration(
          color: getCustomColor(context) == Colors.black
              ? const Color(0xFF1B1B1B)
              : CupertinoColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(0)),
        ),
        primaryColor: Colors.blue,
        secondaryColor: Colors.white,
        messageInsetsVertical: double.parse(8.toString()),
        messageInsetsHorizontal: double.parse(14.toString()),
        dateDividerTextStyle: TextStyle(
            color: getCustomColor(context) == Colors.black
                ? CupertinoColors.white
                : CupertinoColors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none),
        sentMessageBodyTextStyle: const TextStyle(
            decoration: TextDecoration.none,
            color: CupertinoColors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal),
        receivedMessageBodyTextStyle: generateReceivedMessageBodyTextStyle());

    final appBarColor = getCustomColor(context) == Colors.black
        ? const Color(0xFF1B1B1B)
        : CupertinoColors.white;

    final appBarTextColor = getCustomColor(context) == Colors.black
        ? CupertinoColors.white
        : CupertinoColors.black;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.contact.name,
          style: TextStyle(
            color: appBarTextColor,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            //todo open contact info page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatInfoScreen(
                  contact: widget.contact,
                ),
              ),
            );
          },
          //user image
          child: CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.contact.image),
          ),
        ),
        backgroundColor: appBarColor,
      ),
      child: Container(
        color: getCustomColor(context) == Colors.black
            ? const Color(0xFF1B1B1B)
            : CupertinoColors.white,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard
              final currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: Material(
              child: Chat(
                bubbleBuilder: _bubbleBuilder,
                messages: _messages.toList(),
                user: types.User(id: currentUserId), // Set the current user
                emptyState: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Say Hello to ${widget.contact.name}!',
                        style: TextStyle(
                            color: getCustomColor(context) ==
                                    const Color(0xFF1B1B1B)
                                ? const Color(0xFF8E8E8E)
                                : const Color(0xFF8E8E8E),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                onAttachmentPressed: _handleAttachmentPressed,
                onSendPressed: _handleSendPressed,
                theme: theme,
                hideBackgroundOnEmojiMessages: true,
                scrollToUnreadOptions: const ScrollToUnreadOptions(
                    //todo
                    ),
                isAttachmentUploading: false,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                inputOptions: InputOptions(
                  inputClearMode: InputClearMode.always,
                  keyboardType: TextInputType.multiline,
                  onTextChanged: (text) {
                    // Handle text changed
                  },
                  enableSuggestions: true,
                  enabled: true,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                typingIndicatorOptions: const TypingIndicatorOptions(
                  typingMode: TypingIndicatorMode.name,
                ),
                usePreviewData: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
