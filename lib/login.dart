import 'dart:async';
// import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_button/constants.dart';
import 'package:sign_button/create_button.dart';

import 'package:mychat/const.dart';
import 'package:mychat/home.dart';
// import 'package:mychat/widget/loading.dart';
import 'package:mychat/model/chat_user.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  // final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  // final GoogleSignIn googleSignIn = GoogleSignIn();
  // final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences? prefs;

  bool isLoading = false;
  bool isLogIn = false;

  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _titleText = "Sign In";
  String _changeSign = "NEED REGISTER?";
  String _buttonText = "LOGIN";

  // final AuthCredential authCredential = GoogleAuthProvider.getCredential();
  // final AuthCredential authCredential = GoogleAuthProvider.credential();

  // bool isLoading = false;
  // bool isLogIn = false;
  // User? currentUser;

  @override
  void initState() {
    super.initState();
    isSignIn();
  }

  void isSignIn() async {
    // this.setState(() {
    //   isLoading = true;
    // });

    // prefs = await SharedPreferences.getInstance();

    // isLogIn = await _googleSignIn.isSignedIn();
    // if (isLogIn && prefs?.getString('id') != null) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) =>
    //             HomeScreen(currentUserId: prefs!.getString('id') ?? "")),
    //   );
    // }

    // this.setState(() {
    //   isLoading = false;
    // });
  }

  Future<Null> _handleSignIn() async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      User? user = userCredential.user;

      if (user != null) {
        await _firestore
            .collection("user")
            .where("uid", isEqualTo: user.uid)
            .get()
            .then((QuerySnapshot querySnapshot) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(currentUid: user.uid))));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        _buildAlert("Wrong password provided for that user.");
      }
      if (e.code == "user-not-found") {
        _buildAlert("No user found for that email.");
      } else if (e.code == "wrong-password") {
        _buildAlert("Wrong password provided for that user.");
      }
    } catch (e) {
      _buildAlert(e.toString());
    }
  }

  Future<Null> _handleSignUp() async {
    try {
      if (_nameController.text.length < 1) {
        _buildMsg("Please fill in your name.");
        return null;
      }

      if (_emailController.text.length < 1) {
        _buildMsg("Please fill in your email.");
        return null;
      }

      if (_passwordController.text.length < 1) {
        _buildMsg("Please fill in your password.");
        return null;
      }

      if (_passwordController.text != _confirmController.text) {
        _buildMsg("Please check your password again.");
        return null;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      User? user = userCredential.user;

      if (user != null) {
        _firestore.collection("user").add({
          "uid": user.uid,
          "email": user.email,
          "name": _nameController.text,
          "photoUrl": "",
          "about": ""
        });
        _firestore.collection("room").add({"uid": user.uid, "cid": []});
      }

      _buildMsg("Sign up completed.");

      setState(() {
        _titleText = "Sign In";
        _changeSign = "NEED REGISTER?";
        _buttonText = "LOGIN";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
        _buildMsg("The password provided is too weak.");
      } else if (e.code == "email-already-in-use") {
        _buildMsg("The account already exists for that email.");
      }
    } catch (e) {
      _buildMsg(e.toString());
    }
  }

  // void _goSignIn(){}

  // void _confirmPassword() {
  //   final confirmController = TextEditingController();
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           content: Column(children: <Widget>[
  //             Text("Please enter your password again."),
  //             TextField(
  //               controller: confirmController,
  //               obscureText: true,
  //               style: TextStyle(color: fontColor),
  //               decoration: InputDecoration(
  //                   enabledBorder: UnderlineInputBorder(
  //                       borderSide: BorderSide(color: fontColor)),
  //                   focusedBorder: UnderlineInputBorder(
  //                       borderSide: BorderSide(color: fontColor)),
  //                   labelText: "Confirm Password",
  //                   labelStyle: TextStyle(color: fontColor)),
  //             ),
  //           ]),
  //           actions: <Widget>[
  //             Container(
  //               child: IconButton(
  //                 icon: const Icon(Icons.close),
  //                 color: exitColor,
  //                 onPressed: () async {
  //                   if (_passwordController.text == confirmController.text) {
  //                     Navigator.pop(context, "close");
  //                   }
  //                 },
  //               ),
  //               alignment: Alignment.centerRight,
  //             )
  //           ],
  //         );
  //       });
  // }

  // Future<Null> handleSignIn() async {
  //   prefs = await SharedPreferences.getInstance();

  //   this.setState(() {
  //     isLoading = true;
  //   });

  //   GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //   if (googleUser != null) {
  //     GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     User? firebaseUser =
  //         (await firebaseAuth.signInWithCredential(credential)).user;

  //     if (firebaseUser != null) {
  //       // Check is already sign up
  //       final QuerySnapshot result = await FirebaseFirestore.instance
  //           .collection('user')
  //           .where('id', isEqualTo: firebaseUser.uid)
  //           .get();
  //       final List<DocumentSnapshot> documents = result.docs;
  //       if (documents.length == 0) {
  //         // Update data to server if new user
  //         FirebaseFirestore.instance
  //             .collection('user')
  //             .doc(firebaseUser.uid)
  //             .set({
  //           'name': firebaseUser.displayName,
  //           'id': firebaseUser.uid,
  //           'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
  //           'chattingWith': null
  //         });

  //         // Write data to local
  //         currentUser = firebaseUser;
  //         await prefs?.setString('id', currentUser!.uid);
  //         await prefs?.setString('name', currentUser!.displayName ?? "");
  //       } else {
  //         DocumentSnapshot documentSnapshot = documents[0];
  //         UserChat userChat = UserChat.fromDocument(documentSnapshot);
  //         // Write data to local
  //         await prefs?.setString('id', userChat.id);
  //         await prefs?.setString('name', userChat.name);
  //         await prefs?.setString('about', userChat.about);
  //       }
  //       Fluttertoast.showToast(msg: "Sign in success");
  //       this.setState(() {
  //         isLoading = false;
  //       });

  //       Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) =>
  //                   HomeScreen(currentUserId: firebaseUser.uid)));
  //     } else {
  //       Fluttertoast.showToast(msg: "Sign in fail");
  //       this.setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   } else {
  //     Fluttertoast.showToast(msg: "Google Sign in fail");
  //     this.setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  void _buildMsg(String msg) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(msg),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.close),
                color: exitColor,
                onPressed: () => Navigator.pop(context, "OK"),
              )
            ],
          );
        });
  }

  void _buildAlert(String error) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(
                "$error\n\nemail: ${_emailController.text}\n\npassword: ${_passwordController.text}"),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.close),
                color: exitColor,
                onPressed: () => Navigator.pop(context, "OK"),
              )
            ],
          );
        });
  }

  Widget _buildForm(String label) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 60.0,
      child: TextField(
        controller: (label == "Password")
            ? _passwordController
            : ((label == "Confirm Password")
                ? _confirmController
                : ((label == "Name") ? _nameController : _emailController)),
        obscureText: label.contains("Password") ? true : false,
        style: TextStyle(color: whiteColor),
        decoration: InputDecoration(
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: whiteColor)),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: whiteColor)),
            labelText: label,
            labelStyle: TextStyle(color: whiteColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(gradient: themeGradient),
          ),
          Container(
            height: double.infinity,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 120.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(_titleText,
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 28.0,
                        fontWeight: FontWeight.w500,
                      )),
                  SizedBox(height: 40.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      (_buttonText == "LOGIN")
                          ? SizedBox(height: 0)
                          : _buildForm("Name"),
                      // SizedBox(height: 20.0),
                      _buildForm("Email"),
                      // SizedBox(height: 20.0),
                      _buildForm("Password"),
                      (_buttonText == "LOGIN")
                          ? SizedBox(height: 0)
                          : _buildForm("Confirm Password"),
                      Container(
                        child: TextButton(
                            child: Text(_changeSign),
                            style: TextButton.styleFrom(
                                primary: whiteColor,
                                textStyle: TextStyle(
                                  color: whiteColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12.0,
                                )),
                            onPressed: () {
                              if (_buttonText == "LOGIN") {
                                setState(() {
                                  _titleText = "Sign Up";
                                  _changeSign = "NEED LOGIN?";
                                  _buttonText = "REGISTER";
                                });
                              } else {
                                setState(() {
                                  _titleText = "Sign In";
                                  _changeSign = "NEED REGISTER?";
                                  _buttonText = "LOGIN";
                                });
                              }
                            }),
                        alignment: Alignment.centerRight,
                      ),
                      SizedBox(height: 5.0),
                      Container(
                        height: 60.0,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: ElevatedButton(
                            child: Text(_buttonText),
                            style: ElevatedButton.styleFrom(
                                textStyle: TextStyle(fontSize: 20.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                primary: whiteColor,
                                onPrimary: fontColor),
                            onPressed: () => (_buttonText == "LOGIN")
                                ? _handleSignIn()
                                : _handleSignUp()),
                      ),
                      SizedBox(height: 20.0),
                      (_buttonText == "LOGIN")
                          ? Center(
                              child: Text("- OR -",
                                  style: TextStyle(color: whiteColor)),
                            )
                          : SizedBox(height: 0),
                      (_buttonText == "LOGIN")
                          ? SizedBox(height: 20.0)
                          : SizedBox(height: 0),
                      // Center(
                      //   child: Text("Sign In with",
                      //       style:
                      //           TextStyle(color: whiteColor, fontSize: 12.0)),
                      // ),
                      // SizedBox(height: 10.0),
                      (_buttonText == "LOGIN")
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SignInButton.mini(
                                    buttonType: ButtonType.google,
                                    elevation: 2,
                                    onPressed: () => {}),
                                SignInButton.mini(
                                    buttonType: ButtonType.amazon,
                                    elevation: 2,
                                    onPressed: () => {}),
                                SignInButton.mini(
                                    buttonType: ButtonType.facebook,
                                    elevation: 2,
                                    onPressed: () => {}),
                              ],
                            )
                          : SizedBox(height: 0),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: themeColor,
    );
  }
}
