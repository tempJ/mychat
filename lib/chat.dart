import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mychat/model/chat_chat.dart';
import 'package:mychat/model/chat_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mychat/const.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen(
      {Key? key,
      required this.currentUid,
      required this.chatRoomId,
      required this.title,
      required this.uids})
      : super(key: key);

  final String currentUid;
  final String chatRoomId;
  String title;
  List<String> uids;

  @override
  ChatScreenState createState() => ChatScreenState(
      currentUid: currentUid, chatRoomId: chatRoomId, title: title, uids: uids);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState(
      {Key? key,
      required this.currentUid,
      required this.chatRoomId,
      required this.title,
      required this.uids});
  SharedPreferences? prefs;

  final _firestore = FirebaseFirestore.instance;

  final String currentUid;
  final String chatRoomId;
  String title;
  List<String> uids;
  List<QueryDocumentSnapshot> chatList = new List.from([]);
  // List<Map<Timestamp, String>> chatting = [];

  Set<ChatUser> participant = Set();

  final _listScrollController = ScrollController();
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() {
    for (var uid in uids) {
      _firestore
          .collection("user")
          .doc(uid)
          .get()
          .then((DocumentSnapshot document) async {
        participant.add(new ChatUser.fromDocument(document));
      });
    }
  }

  Future<bool> _onBackPress() {
    Navigator.pop(context);

    return Future.value(false);
  }

  void _onSendChat() {
    final msg = _inputController.text;
    Timestamp now = Timestamp.now();

    if (msg.isNotEmpty) {
      _inputController.clear();

      final documentReference = _firestore
          .collection("chat")
          .doc(chatRoomId)
          .collection(chatRoomId)
          .doc(now.millisecondsSinceEpoch.toString());

      _firestore.runTransaction((transaction) async {
        transaction.set(documentReference,
            {"uid": currentUid, "timestamp": now, "content": msg});
      });
    }
  }

  // Widget _buildChat(int idx, DocumentSnapshot? document) {
  //   final item;

  //   if (document != null) {
  //     ChatChat chat = ChatChat.fromDocument(document);
  //     item = chat.context[idx];
  //   } else {
  //     item = chatting[idx];
  //   }

  //   final line = item.values.first.split(":");
  //   final uid = line.first;
  //   final msg = line.sublist(1).join(":");

  //   final time = item.keys.first.toDate();

  //   return Container(
  //     margin: EdgeInsets.all(3.0),
  //     child: Row(
  //       children: <Widget>[
  //         Container(
  //           width: 50.0,
  //           child: Text(
  //             uid,
  //             // overflow: TextOverflow.vi,
  //           ),
  //         ),
  //         Container(
  //           width: 150.0,
  //           child: Text(
  //             msg,
  //             overflow: TextOverflow.visible,
  //           ),
  //         ),
  //         Container(
  //           padding: EdgeInsets.all(3.0),
  //           alignment: Alignment.center,
  //           width: 40.0,
  //           decoration: BoxDecoration(
  //               color: whiteColor,
  //               borderRadius: BorderRadius.all(Radius.circular(20))),
  //           child: Text(
  //             "${time.hour}:${time.minute}",
  //             style: TextStyle(fontSize: 11.0),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _makeBubble(bool isCurrentUser, String content) {
    return Container(
      // color: (isCurrentUser) ? myBubbleColor : yourBubbleColor,
      margin: EdgeInsets.all(5.0),
      padding: EdgeInsets.all(10.0),
      constraints: BoxConstraints(maxWidth: 200.0),
      decoration: BoxDecoration(
          color: (isCurrentUser) ? myBubbleColor : yourBubbleColor,
          borderRadius: (isCurrentUser)
              ? BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                )
              : BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                )),
      child: Text(
        content,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _makeTime(DateTime time) {
    String hour = "0" + time.hour.toString();
    String minute = "0" + time.minute.toString();

    return Container(
      margin: EdgeInsets.all(5.0),
      padding: EdgeInsets.all(3.0),
      alignment: Alignment.center,
      width: 40.0,
      decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Text(
        "${(hour.length > 2) ? time.hour : hour}:${(minute.length > 2) ? time.minute : minute}",
        style: TextStyle(fontSize: 11.0),
      ),
    );
  }

  Widget _buildChat(int idx, DocumentSnapshot? document) {
    if (document != null) {
      String uid = document.get("uid");
      Timestamp timestamp = document.get("timestamp");
      DateTime dateTime = timestamp.toDate();

      if (uid == currentUid) {
        return Container(
          margin: EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _makeTime(dateTime),
              _makeBubble(true, document.get("content"))
            ],
          ),
        );
      } else {
        ChatUser user = participant.firstWhere((part) => part.id == uid);
        Widget pic = defaultPic;
        if (user.photoURL != "") {
          pic = Image.network(
            user.photoURL,
            width: 50,
            height: 50,
            fit: BoxFit.fill,
          );
        }

        return Container(
          margin: EdgeInsets.all(3.0),
          child: Row(
            children: <Widget>[
              // Text(user.photoURL),
              Column(
                children: <Widget>[
                  // Container(onPress:)
                  Material(
                    child: pic,
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: 50.0,
                    child: Text(
                      user.name,
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                ],
              ),
              _makeBubble(false, document.get("content")),
              _makeTime(dateTime),
            ],
          ),
        );
      }
    } else {
      return SizedBox();
    }
  }

  Widget _buildChatList() {
    return Flexible(
        child: StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("chat")
          .doc(chatRoomId)
          .collection(chatRoomId)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          chatList.addAll(snapshot.data!.docs);
          return ListView.builder(
            padding: EdgeInsets.all(10.0),
            itemBuilder: (context, idx) =>
                _buildChat(idx, snapshot.data?.docs[idx]),
            itemCount: snapshot.data?.docs.length,
            reverse: true,
            controller: _listScrollController,
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(darkGreyColor),
            ),
          );
        }
      },
    ));
  }

  // Widget _buildChattingList() {
  //   return Flexible(
  //       child: ListView.builder(
  //     padding: EdgeInsets.all(10.0),
  //     itemBuilder: (BuildContext context, int idx) {
  //       return _buildChat(idx, null);
  //     },
  //     itemCount: chatting.length,
  //     reverse: true,
  //     controller: _listScrollController,
  //   ));
  //   //     child: StreamBuilder<QuerySnapshot>(
  //   //   stream: _firestore
  //   //       .collection("chat")
  //   //       .where("cid", isEqualTo: cid)
  //   //       .orderBy("timestamp", descending: true)
  //   //       .snapshots(),
  //   //   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
  //   //     if (snapshot.hasData) {
  //   //       chatList.addAll(snapshot.data!.docs);
  //   //       return ListView.builder(
  //   //         padding: EdgeInsets.all(10.0),
  //   //         itemBuilder: (context, idx) =>
  //   //             _buildChat(idx, snapshot.data?.docs[idx]),
  //   //         itemCount: snapshot.data?.docs.length,
  //   //         reverse: true,
  //   //         controller: _listScrollController,
  //   //       );
  //   //     } else {
  //   //       return Center(
  //   //         child: CircularProgressIndicator(
  //   //           valueColor: AlwaysStoppedAnimation<Color>(darkGreyColor),
  //   //         ),
  //   //       );
  //   //     }
  //   //   },
  //   // ));
  // }

  Widget _buildInput() {
    return Container(
      color: whiteColor,
      child: Row(
        children: <Widget>[
          Flexible(
              child: Container(
            height: 35.0,
            margin: EdgeInsets.all(10.0),
            child: TextFormField(
              controller: _inputController,
              style: TextStyle(color: fontColor),
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: darkGreyColor)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: darkGreyColor)),
              ),
            ),
          )),
          IconButton(
              icon: Icon(
                Icons.send,
                color: darkGreyColor,
              ),
              onPressed: () => _onSendChat()
              // () {
              //   if (_inputController.text.isNotEmpty) {
              //     final Timestamp date = Timestamp.fromDate(DateTime.now());
              //     final String msg = "$currentUid:${_inputController.text}";
              //     setState(() {
              //       chatting.add({date: msg});
              //     });
              //     _inputController.text = "";
              //   }
              // },
              )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Container(
            height: double.infinity,
            width: double.infinity,
            color: lightGreyColor,
          ),
          Column(
            children: <Widget>[_buildChatList(), _buildInput()],
          )
        ],
      ),
    );
    // WillPopScope(
    //   child: Stack(
    //     children: <Widget>[
    //       Container(
    //         height: double.infinity,
    //         width: double.infinity,
    //         color: whiteColor,
    //       ),
    //       // Column(
    //       //   children: <Widget>[_buildChatList(), _buildInput()],
    //       // )
    //     ],
    //   ),
    //   onWillPop: _onBackPress,
    // );
  }
}
