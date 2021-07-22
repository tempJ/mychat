import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  ChatUser({
    required this.id,
    required this.myid,
    required this.email,
    required this.name,
    required this.photoURL,
    this.about,
  });

  final String id;
  String myid;
  String email;
  String name;
  String photoURL;
  String? about;

  factory ChatUser.fromDocument(DocumentSnapshot doc) {
    String myid = "";
    String email = "";
    String name = "";
    String photoURL = "";
    String? about = null;

    try {
      myid = doc.get("myid");
    } catch (e) {}

    try {
      email = doc.get("email");
    } catch (e) {}

    try {
      name = doc.get("name");
    } catch (e) {}

    try {
      photoURL = doc.get("photoURL");
    } catch (e) {}

    try {
      about = doc.get("about");
    } catch (e) {}

    return ChatUser(
        id: doc.id,
        myid: myid,
        email: email,
        name: name,
        photoURL: photoURL,
        about: about);
  }
}
