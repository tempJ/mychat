import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChat {
  ChatChat({required this.id, required this.head, required this.context});

  final String id;

  String head;
  List<Map<Timestamp, String>> context;

  factory ChatChat.fromDocument(DocumentSnapshot doc) {
    String head = "";
    List<Map<Timestamp, String>> context = [];

    try {
      head = doc.get("head");
    } catch (e) {}

    try {
      context = List.from(doc.get("context"));
    } catch (e) {}

    return ChatChat(id: doc.id, head: head, context: context);
  }
}
