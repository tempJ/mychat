import 'dart:async';
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

import 'package:mychat/model/chat_room.dart';
import 'package:mychat/model/chat_user.dart';
import 'package:mychat/widget/toast.dart';

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
      showToast(err.message.toString());
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
    // Set<String> uidSet =
    Map<String, String>? userMap = await showDialog(
        context: context,
        builder: (context) {
          return AddDialog(currentUid);
        });
    if (userMap == null) {
    } else if (userMap.isNotEmpty) {
      await _firestore
          .collection("user")
          .doc(currentUid)
          .get()
          .then((DocumentSnapshot document) {
        ChatUser user = ChatUser.fromDocument(document);
        userMap[currentUid] = user.name;
      });
      showToast(userMap.length.toString());

      // List<String> users = [];

      // for (String uid in uidSet) {
      //   await _firestore
      //       .collection("user")
      //       .doc(uid)
      //       .get()
      //       .then((DocumentSnapshot document) {
      //     ChatUser user = ChatUser.fromDocument(document);
      //     users.add(user.name);
      //   });
      // }

      final document = await _firestore.collection("room").add({
        "iconURL": "",
        "title": (userMap.length == 1) ? "Me" : userMap.values.join(", "),
        "last": "",
        "uids": userMap.keys.toList(),
      });

      await _firestore
          .collection("chat")
          .doc(document.id)
          .set({"head": currentUid});
    } else {}
  }

  Widget _buildRoom(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      ChatRoom room = ChatRoom.fromDocument(document);
      Widget icon = defaultPic;
      if (room.iconURL != "") {
        try {
          icon = Image.network(room.iconURL,
              width: 50, height: 50, fit: BoxFit.fill);
        } catch (e) {}
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
              MaterialPageRoute(builder: (context) {
                // Set<ChatUser> participant = Set();
                // // for (var uid in room.uids) {
                //   _firestore
                //       .collection("user")
                //       .doc(uid)
                //       .get()
                //       .then((DocumentSnapshot document) async {
                //     participant.add(new ChatUser.fromDocument(document));
                //   });
                // }

                return ChatScreen(
                    currentUid: currentUid,
                    chatRoomId: room.id,
                    title: room.title,
                    iconURL: room.iconURL,
                    uids: room.uids);
              }),
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

  // void _getUser() async {
  //   for (var uid in uids) {
  //     await _firestore
  //         .collection("user")
  //         .doc(uid)
  //         .get()
  //         .then((DocumentSnapshot document) async {
  //       participant.add(new ChatUser.fromDocument(document));
  //     });
  //   }
  // }

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

  // Set<String> nameSet = Set();
  // Set<String> uidSet = Set();
  // Set<Map<String, String>> userSet = Set();
  Map<String, String> userMap = Map();
  final _addController = TextEditingController();

  List<Widget> _buildChip() {
    List<Widget> chipList = [];
    userMap.forEach((id, name) => chipList.add(Chip(
          label: Text(
            name,
            // style: TextStyle(color: fontColor),
          ),
          backgroundColor: Colors.blueGrey.shade100,
          deleteIcon: Icon(
            Icons.close,
            size: 16.0,
          ),
          deleteIconColor: Colors.redAccent,
          onDeleted: () => setState(() {
            userMap.remove(id);
          }),
        )));
    return chipList;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        height: 150.0,
        child: Column(children: <Widget>[
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
              Center(
                  child: Material(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                color: whiteColor,
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  alignment: Alignment.center,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: fontColor,
                  onPressed: () {
                    // if(){return null;}
                    _firestore
                        .collection("user")
                        .where("myid", isEqualTo: _addController.text)
                        .get()
                        .then((QuerySnapshot snapshot) {
                      if (snapshot.docs.isNotEmpty) {
                        ChatUser user = ChatUser.fromDocument(snapshot.docs[0]);
                        // if (user.id != currentUid) {
                        setState(() {
                          // nameSet.add(user.name);
                          // uidSet.add(user.id);
                          userMap[user.id] = user.name;
                          // userSet.add();
                        });
                        // } else {
                        //   showToast("This is your ID");
                        // }
                      } else {
                        showToast("Not found ID: ${_addController.text}");
                      }
                    });
                  },
                ),
              )),
            ],
          ),
          SizedBox(height: 15),
          // Container(
          //   margin: EdgeInsets.all(5),
          //   child: Divider(
          //     // indent: 30,
          //     // endIndent: 30,
          //     color: darkGreyColor,
          //   ),
          // ),
          Wrap(
            spacing: 30.0,
            children: _buildChip(),
          )
        ]),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("OK"),
          onPressed: () => Navigator.pop(context, userMap),
        ),
        TextButton(
          child: Text("Cancle"),
          onPressed: () => Navigator.pop(context, null),
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
