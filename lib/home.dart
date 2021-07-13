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

import 'package:mychat/const.dart';
import 'package:mychat/main.dart';
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
        showNotification(message.notification!);
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

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => ChatSettings()));
    }
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dfa.flutterchatdemo'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    print(remoteNotification);

    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: fontColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: fontColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: fontColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: fontColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
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

  void _buildAlert(String str) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(content: Text(str));
        });
  }

  // Map<String, Object?> toJson(){
  //   return {
  //     ''
  //   }
  // }

  Widget _buildRoom(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      ChatRoom chatRoom = ChatRoom.fromDocument(document);
      return Container(
        child: TextButton(
          child: Row(
            children: <Widget>[
              Material(
                child: Icon(
                  Icons.account_circle,
                  size: 50.0,
                  color: darkGreyColor,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          "user name 표시될 구역",
                          maxLines: 1,
                          style: TextStyle(color: fontColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          "msg 일부 표시될 구역",
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
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => Chat(
            //       peerId: userChat.id,
            //       peerAvatar: Icons.account_circle,
            //     ),
            //   ),
            // );
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

  Future<QuerySnapshot> _fetchChatUser(uid) async {
    return await _firestore
        .collection("user")
        .where("uid", isEqualTo: uid)
        .get();
  }

  Future<QuerySnapshot> _fetchChat(uid) async {
    return await _firestore
        .collection("chat")
        .where("cid", isEqualTo: uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(Icons.chat_bubble_rounded),
        backgroundColor: themeColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          // Container(
          //   child: FutureBuilder(builder: (context, snapshot){},)
          // )
          Container(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("room")
                  .where("uid", isEqualTo: currentUid)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                      DocumentSnapshot? documentRoom =
                          snapshot.data?.docs[index];
                      if (documentRoom != null) {
                        ChatRoom chatRoom = ChatRoom.fromDocument(documentRoom);
                        // DocumentSnapshot? documentUser = await _fetchChatUser(chatRoom.uid);

                        final documentChat = _firestore
                            .collection("chat")
                            .where("cid", isEqualTo: chatRoom.cid);
                      }

                      // ChatUser chatUser = ChatUser.fromDocument(documentUser);
                      return _buildRoom(context, documentRoom);
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
        onPressed: () {},
      ),
      // body: WillPopScope(
      //   child: Stack(
      //     children: <Widget>[
      //       // List
      //       Container(
      //         child: StreamBuilder<QuerySnapshot>(
      //           stream: FirebaseFirestore.instance
      //               .collection('users')
      //               .limit(_limit)
      //               .snapshots(),
      //           builder: (BuildContext context,
      //               AsyncSnapshot<QuerySnapshot> snapshot) {
      //             if (snapshot.hasData) {
      //               return ListView.builder(
      //                 padding: EdgeInsets.all(10.0),
      //                 itemBuilder: (context, index) =>
      //                     buildItem(context, snapshot.data?.docs[index]),
      //                 itemCount: snapshot.data?.docs.length,
      //                 controller: listScrollController,
      //               );
      //             } else {
      //               return Center(
      //                 child: CircularProgressIndicator(
      //                   valueColor: AlwaysStoppedAnimation<Color>(fontColor),
      //                 ),
      //               );
      //             }
      //           },
      //         ),
      //       ),

      //       // Loading
      //       Positioned(
      //         child: isLoading ? const Loading() : Container(),
      //       )
      //     ],
      //   ),
      //   onWillPop: rc,
      // ),
    );
  }
}

class Choice {
  const Choice({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
