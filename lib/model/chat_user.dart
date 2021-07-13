import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id;
  final String uid;
  String email;
  String name;
  String? photoURL;
  String? about;

  ChatUser({
    required this.id,
    required this.uid,
    required this.email,
    required this.name,
    this.photoURL,
    this.about,
  });

  factory ChatUser.fromDocument(DocumentSnapshot doc) {
    String uid = "";
    String email = "";
    String name = "";
    String? photoURL = null;
    String? about = null;

    try {
      uid = doc.get("uid");
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
        uid: uid,
        email: email,
        name: name,
        photoURL: photoURL,
        about: about);
  }

  // factory ChatUser.fromFuture(DocumentSnapshot doc)  {
  //   String uid = "";
  //   String email = "";
  //   String name = "";
  //   String? photoURL = null;
  //   String? about = null;

  //   try {
  //     uid = doc.get("uid");
  //   } catch (e) {}

  //   try {
  //     email = doc.get("email");
  //   } catch (e) {}

  //   try {
  //     name = doc.get("name");
  //   } catch (e) {}

  //   try {
  //     photoURL = doc.get("photoURL");
  //   } catch (e) {}

  //   try {
  //     about = doc.get("about");
  //   } catch (e) {}

  //   return ChatUser(
  //       id: doc.id,
  //       uid: uid,
  //       email: email,
  //       name: name,
  //       photoURL: photoURL,
  //       about: about);
  // }
}
