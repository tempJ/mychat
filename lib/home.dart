import 'dart:async';
// import 'dart:html';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mychat/chat.dart';

import 'package:mychat/const.dart';
import 'package:mychat/main.dart';
import 'package:mychat/model/chat_chat.dart';
import 'package:mychat/model/chat_room.dart';
import 'package:mychat/model/chat_user.dart';
import 'package:mychat/widget/loading.dart';

class HomeScreen extends StatefulWidget {
  final String currentUid;

  HomeScreen({Key? key, required this.currentUid}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUid: currentUid);
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({Key? key, required this.currentUid});

  final String currentUid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  // final _addController = TextEditingController();
  // List<String>? addId;
  // Set<String> _addId = Set();

  int _limit = 20;
  int _limitIncrement = 20;
  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
    listScrollController.addListener(scrollListener);
  }

  void registerNotification() {
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      if (message.notification != null) {
        // showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  void _buildAddChat() async {
    Set<String> uidSet = await showDialog(
        context: context,
        builder: (context) {
          return AddDialog(currentUid);
        });

    if (uidSet.isNotEmpty) {
      uidSet.add(currentUid);
      List<String> users = [];

      for (String uid in uidSet) {
        await _firestore
            .collection("user")
            .doc(uid)
            .get()
            .then((DocumentSnapshot document) {
          ChatUser user = ChatUser.fromDocument(document);
          users.add(user.name);
        });
      }

      final document = await _firestore.collection("room").add({
        "iconUrl": "",
        "title": (users.length < 3) ? users.first : users.join(", "),
        "last": "",
        "uids": uidSet.toList(),
      });

      await _firestore
          .collection("chat")
          .doc(document.id)
          .set({"head": currentUid, "context": []});
    }
  }

  Widget _buildRoom(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      ChatRoom room = ChatRoom.fromDocument(document);
      Widget icon = defaultPic;
      if (room.iconUrl != "") {
        icon = Image.network(room.iconUrl,
            width: 50, height: 50, fit: BoxFit.fill);
      }

      return Container(
        child: TextButton(
          child: Row(
            children: <Widget>[
              Material(
                child: icon,
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          room.title,
                          maxLines: 1,
                          style: TextStyle(color: fontColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          room.last,
                          maxLines: 1,
                          style: TextStyle(color: fontColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                    currentUid: currentUid,
                    chatRoomId: room.id,
                    title: room.title,
                    uids: room.uids),
              ),
            );
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(lightGreyColor),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
      // }
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(Icons.chat_bubble_rounded),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Container(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("room")
                  .where("uids", arrayContains: currentUid)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                      DocumentSnapshot? document = snapshot.data?.docs[index];
                      return _buildRoom(context, document);
                    },
                    itemCount: snapshot.data?.docs.length,
                    controller: listScrollController,
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(darkGreyColor),
                    ),
                  );
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        elevation: 2,
        backgroundColor: themeColor,
        onPressed: () => _buildAddChat(),
      ),
    );
  }
}

class AddDialog extends StatefulWidget {
  AddDialog(this.currentUid);

  final String currentUid;

  @override
  AddDialogState createState() => new AddDialogState(currentUid);
}

class AddDialogState extends State<AddDialog> {
  AddDialogState(this.currentUid);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String currentUid;

  Set<String> nameSet = Set();
  Set<String> uidSet = Set();
  final _addController = TextEditingController();
  String? errMsg;

  List<Widget> _buildChip() {
    return nameSet
        .map((e) => Chip(
              label: Text(e),
              backgroundColor: lightGreyColor,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                  child: Container(
                height: 50.0,
                child: TextField(
                  style: TextStyle(color: fontColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: lightGreyColor,
                    errorText: errMsg,
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0)),
                    errorBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30.0)),
                  ),
                  controller: _addController,
                ),
              )),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: darkGreyColor,
                onPressed: () {
                  _firestore
                      .collection("user")
                      .where("myid", isEqualTo: _addController.text)
                      .get()
                      .then((QuerySnapshot snapshot) {
                    if (snapshot.docs.isNotEmpty) {
                      ChatUser user = ChatUser.fromDocument(snapshot.docs[0]);
                      setState(() {
                        errMsg = null;
                        nameSet.add(user.name);
                        uidSet.add(user.id);
                      });
                    } else {
                      setState(() {
                        errMsg = "Not found ID: ${_addController.text}";
                      });
                    }
                  });
                },
              )
            ],
          ),
          // SizedBox(height: 10.0),
          Container(
              // height: 30.0,
              child: Wrap(
            children: _buildChip(),
          ))
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text("OK"),
          style: TextButton.styleFrom(
              textStyle: TextStyle(
            color: fontColor,
            fontWeight: FontWeight.normal,
            // fontSize: 12.0,
          )),
          onPressed: () => Navigator.pop(context, uidSet),
        ),
        TextButton(
          child: Text("Cancle"),
          style: TextButton.styleFrom(
              textStyle: TextStyle(
            color: fontColor,
            fontWeight: FontWeight.normal,
            // fontSize: 12.0,
          )),
          onPressed: () => Navigator.pop(context, Set()),
        )
      ],
    );
  }
}

class Choice {
  const Choice({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
