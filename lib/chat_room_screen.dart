import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:audioplayers/audioplayers.dart';

class ChatPage extends StatefulWidget {
  final FavoriteUser contact;

  const ChatPage({super.key, required this.contact});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

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

    bool isShortMessage = (message as types.TextMessage).text.length <= 20;

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
          child,
          if (isShortMessage)
            const SizedBox(height: 0)
          else
            const SizedBox(height: 0), // Adjust the spacing as needed
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

      // Fetch messages from the chat room that exists or fallback to the other one
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
        final messages = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final authorId = data['author_id'] as String?;
          final createdAt =
              (data['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final text = data['text'] as String?;

          return types.TextMessage(
            author: types.User(
              id: authorId ?? '',
            ),
            createdAt: createdAt,
            id: doc.id,
            text: text ?? '',
          );
        }).toList();

        _playReceiveMessageSound();

        setState(() {
          _messages.clear();
          _messages.addAll(
              messages); // Reverse the order to show the latest message at the bottom
        });
      });
    } catch (e) {
      // Handle any errors here
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
    final bool isDarkMode = getCustomColor(context) == Colors.black;

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
                enableSuggestions: true,
                enabled: true,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              typingIndicatorOptions: const TypingIndicatorOptions(
                typingMode: TypingIndicatorMode.name,
              ),
              usePreviewData: true,
            ),
          ),
        ),
      ),
    );
  }
}
