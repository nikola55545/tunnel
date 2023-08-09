import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// ignore: unnecessary_import
import 'package:flutter/rendering.dart';
// import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:image_picker/image_picker.dart';

import 'contacts_screen.dart';

class ChatPage extends StatefulWidget {
  final FavoriteUser contact;

  const ChatPage({super.key, required this.contact});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ScrollController _scrollController;
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final List<types.Message> _messages = [
    // Add more messages here
  ];

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

      // Check if either chat room already exists
      final chatRoomRef1 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName1);
      final chatRoomRef2 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName2);

      // Use a batch write to only create a document if it doesn't exist
      final batch = FirebaseFirestore.instance.batch();

      batch.set(chatRoomRef1, {}, SetOptions(merge: true));
      batch.set(chatRoomRef2, {}, SetOptions(merge: true));

      // Add the message to the chat room as a subcollection
      final messageData = {
        'author_id': currentUserId,
        'text': message.text,
        'created_at': FieldValue.serverTimestamp(),
      };
      batch.set(
          chatRoomRef1.collection('messages').doc(newMessage.id), messageData);
      batch.set(
          chatRoomRef2.collection('messages').doc(newMessage.id), messageData);

      await batch.commit();

      // Update the UI with the new message
      setState(() {
        _messages.insert(0, newMessage);
      });
    } catch (e) {
      // Handle any errors here
      print('Error sending message: $e');
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
      // Initialize Firebase if not already initialized
      await Firebase.initializeApp();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final selectedUserId = widget.contact.id;

      // Generate both possible chat room names
      final chatRoomName1 = '$currentUserId-$selectedUserId';
      final chatRoomName2 = '$selectedUserId-$currentUserId';

      // Get references to both possible chat room documents
      final chatRoomRef1 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName1);
      final chatRoomRef2 = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomName2);

      // Fetch messages from the first chat room document
      final messagesSnapshot1 = await chatRoomRef1
          .collection('messages')
          .orderBy('created_at', descending: true)
          .get();
      final messages1 = messagesSnapshot1.docs.map((doc) {
        final data = doc.data();
        return types.TextMessage(
          author: types.User(
            id: data['author_id'],
          ),
          createdAt: data['created_at'].millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'],
        );
      }).toList();

      // Fetch messages from the second chat room document
      final messagesSnapshot2 = await chatRoomRef2
          .collection('messages')
          .orderBy('created_at', descending: true)
          .get();
      final messages2 = messagesSnapshot2.docs.map((doc) {
        final data = doc.data();
        return types.TextMessage(
          author: types.User(
            id: data['author_id'],
          ),
          createdAt: data['created_at'].millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'],
        );
      }).toList();

      // Combine both sets of messages and update the _messages list
      final List<types.TextMessage> allMessages = [...messages1, ...messages2];
      setState(() {
        _messages.addAll(allMessages);
      });
    } catch (e) {
      // Handle any errors here
      print('Error loading messages: $e');
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

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: const types.User(
          id: 'current_user_id',
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: 'current_user_id',
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // _handleCameraSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Camera'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          color: getCustomColor(context) == const Color(0xFF1B1B1B)
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
      receivedMessageBodyTextStyle: const TextStyle(
          decoration: TextDecoration.none,
          color: CupertinoColors.black,
          fontSize: 16,
          fontWeight: FontWeight.normal),
    );

    final appBarColor = getCustomColor(context) == Colors.black
        ? const Color(0xFF1B1B1B)
        : CupertinoColors.white;

    final appBarTextColor = getCustomColor(context) == Colors.black
        ? CupertinoColors.white
        : CupertinoColors.black;

    return CupertinoPageScaffold(
      //add backgorund image

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
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ContactInfo(),
            //   ),
            // );
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
            child: Chat(
              messages: _messages.toList(),
              user: types.User(id: currentUserId), // Set the current user
              emptyState: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Say Hello to ${widget.contact.name}!',
                      style: TextStyle(
                          color:
                              getCustomColor(context) == const Color(0xFF1B1B1B)
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
                sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                autocorrect: true,
                autofocus: false,
                enableSuggestions: true,
                enabled: true,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              typingIndicatorOptions: const TypingIndicatorOptions(
                typingMode: TypingIndicatorMode.name,
              ),
              usePreviewData: true,
              //time in bubble
            ),
          ),
        ),
      ),
    );
  }
}
