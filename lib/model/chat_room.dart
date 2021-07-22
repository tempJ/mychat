import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  ChatRoom(
      {required this.id,
      required this.iconUrl,
      required this.title,
      required this.last,
      required this.uids});

  final String id;

  String iconUrl;
  String title;
  String last;

  List<String> uids;

  factory ChatRoom.fromDocument(DocumentSnapshot doc) {
    String iconUrl = "";
    String title = "";
    String last = "";
    List<String> uids = [];

    try {
      iconUrl = doc.get("iconUrl");
    } catch (e) {}

    try {
      title = doc.get("title");
    } catch (e) {}

    try {
      last = doc.get("last");
    } catch (e) {}

    try {
      uids = List.from(doc.get("uids"));
    } catch (e) {}

    return ChatRoom(
        id: doc.id, iconUrl: iconUrl, title: title, last: last, uids: uids);
  }
}
