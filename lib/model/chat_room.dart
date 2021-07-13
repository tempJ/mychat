import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;

  final String uid;
  List<String> cid;

  ChatRoom({required this.id, required this.uid, required this.cid});

  factory ChatRoom.fromDocument(DocumentSnapshot doc) {
    String uid = "";
    List<String> cid = [];

    try {
      uid = doc.get("uid");
      cid = doc.get("cid");
    } catch (e) {}

    return ChatRoom(id: doc.id, uid: uid, cid: cid);
  }
}
