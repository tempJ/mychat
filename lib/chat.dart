import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mychat/model/chat_chat.dart';
import 'package:mychat/model/chat_user.dart';
import 'package:mychat/widget/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mychat/const.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen(
      {Key? key,
      required this.currentUid,
      required this.chatRoomId,
      required this.title,
      required this.iconURL,
      required this.uids})
      : super(key: key);

  final String currentUid;
  final String chatRoomId;
  String title;
  String iconURL;
  List<String> uids;
  // Set<ChatUser> uids;

  @override
  ChatScreenState createState() => ChatScreenState(
      currentUid: currentUid,
      chatRoomId: chatRoomId,
      title: title,
      iconURL: iconURL,
      uids: uids);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState(
      {Key? key,
      required this.currentUid,
      required this.chatRoomId,
      required this.title,
      required this.iconURL,
      required this.uids});
  SharedPreferences? prefs;

  final _firestore = FirebaseFirestore.instance;

  final String currentUid;
  final String chatRoomId;
  String title;
  String iconURL;
  String? last;

  List<String> uids;
  // Set<ChatUser> uids;
  List<QueryDocumentSnapshot> chatList = new List.from([]);
  // List<Map<Timestamp, String>> chatting = [];

  Set<ChatUser> participant = Set();

  final _listScrollController = ScrollController();
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // participant = Set.from(uids);
    // _getUser().then();
    // _getUser();
    // .then();

    // StreamBuilder<QuerySnapshot>(
    //   stream: _firestore
    //       .collection("chat")
    //       .doc(chatRoomId)
    //       .collection(chatRoomId)
    //       .orderBy("timestamp", descending: true)
    //       .snapshots(),
    //   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    //     if (snapshot.hasData) {
    //       chatList.addAll(snapshot.data!.docs);
    //       last = snapshot.data!.docs.first.get("content");

    //       return ListView.builder(
    //         padding: EdgeInsets.all(10.0),
    //         itemBuilder: (context, idx) =>
    //             _buildChat(context, snapshot.data?.docs[idx]),
    //         itemCount: snapshot.data?.docs.length,
    //         reverse: true,
    //         controller: _listScrollController,
    //       );
    //     } else {
    //       return Center(
    //         child: CircularProgressIndicator(
    //           valueColor: AlwaysStoppedAnimation<Color>(darkGreyColor),
    //         ),
    //       );
    //     }
    //   },
    // )
  }

  void _getUser() async {
    for (var uid in uids) {
      await _firestore
          .collection("user")
          .doc(uid)
          .get()
          .then((DocumentSnapshot document) async {
        participant.add(new ChatUser.fromDocument(document));
      });
    }
  }

  Future<bool> onBackPress() async {
    if (last != null) {
      await _firestore
          .collection("room")
          .doc(chatRoomId)
          .update({"last": last});
    }
    Navigator.pop(context);

    return Future.value(false);
  }

  void _onSendChat() async {
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

  Widget _makeBubble(bool isCurrentUser, String content) {
    return Container(
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

  Widget _buildChat(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      String uid = document.get("uid");
      Timestamp timestamp = document.get("timestamp");
      DateTime dateTime = timestamp.toDate();

      if (uid == currentUid) {
        return Container(
          margin: EdgeInsets.all(3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _makeTime(dateTime),
              _makeBubble(true, document.get("content"))
            ],
          ),
        );
      } else {
        ChatUser user = participant.firstWhere((part) => part.id == uid);
        // ChatUser user = participant.first;
        Widget pic = defaultPic;
        if (user.photoURL != "") {
          try {
            pic = Image.network(
              user.photoURL,
              width: 50,
              height: 50,
              fit: BoxFit.fill,
            );
          } catch (e) {}
        }
        // Fluttertoast.showToast(
        //     msg: (participant.isEmpty) ? "0" : participant.length.toString());

        return Container(
          margin: EdgeInsets.all(3.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Column(
                children: <Widget>[
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
      return SizedBox.shrink();
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
          last = snapshot.data!.docs.first.get("content");

          return ListView.builder(
            padding: EdgeInsets.all(10.0),
            itemBuilder: (context, idx) =>
                _buildChat(context, snapshot.data?.docs[idx]),
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
              onPressed: () => _onSendChat())
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _getUser();
    Widget icon = defaultPic;
    if (iconURL != "") {
      try {
        icon = Image.network(iconURL, fit: BoxFit.fill);
      } catch (e) {}
    }

    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                Icon(
                  Icons.arrow_right,
                  size: 12,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
            backgroundColor: themeColor,
            leading: Transform.scale(
              scale: 0.7,
              child: Container(
                child: icon,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(25.0))),
              ),
            ),
            elevation: 0,
            actions: <Widget>[],
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
        ),
        onWillPop: () => onBackPress());
  }
}
