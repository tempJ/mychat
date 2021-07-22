import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mychat/widget/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_button/constants.dart';
import 'package:sign_button/create_button.dart';

import 'package:mychat/const.dart';
import 'package:mychat/home.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  SharedPreferences? prefs;

  bool isLoading = false;
  bool isLogIn = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _titleText = "Sign In";
  String _changeSign = "NEED REGISTER?";
  String _buttonText = "LOGIN";

  @override
  void initState() {
    super.initState();
    _emailController.text = "test@test.com";
    _passwordController.text = "test1234";
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
            .doc(user.uid)
            .get()
            .then((DocumentSnapshot document) {
          if (document.exists) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(currentUid: user.uid)));
          }
        });

        // .then((DocumentReference documentReference) => Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => HomeScreen(currentUid: user.uid))));
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
    final String myid = _idController.text;
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String confirm = _confirmController.text;

    try {
      if (myid.length < 1) {
        _buildAlert("Please fill in your ID.");
        return null;
      }

      final int ret = await _firestore
          .collection("user")
          .where("myid", isEqualTo: myid)
          .get()
          .then((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return -1;
        }
        return 0;
      });
      if (ret == -1) {
        _buildAlert("This ID already exists.");
        return null;
      }

      if (name.length < 1) {
        _buildAlert("Please fill in your name.");
        return null;
      }

      if (email.length < 1) {
        _buildAlert("Please fill in your email.");
        return null;
      }

      if (password.length < 1) {
        _buildAlert("Please fill in your password.");
        return null;
      }

      if (password != confirm) {
        _buildAlert("Please check your password or confirm password again.");
        return null;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        _firestore.collection("user").doc(user.uid).set({
          "myid": myid,
          "email": email,
          "name": name,
          "photoURL": "",
          "about": ""
        });
      }

      _buildAlert("Sign up completed.");

      setState(() {
        _titleText = "Sign In";
        _changeSign = "NEED REGISTER?";
        _buttonText = "LOGIN";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
        _buildAlert("The password provided is too weak.");
      } else if (e.code == "email-already-in-use") {
        _buildAlert("The account already exists for that email.");
      }
    } catch (e) {
      _buildAlert(e.toString());
    }
  }

  void _buildAlert(String error) {
    showDialog(
        context: context,
        builder: (context) {
          return ShowAlert(error);
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
                : ((label == "Name")
                    ? _nameController
                    : ((label == "ID") ? _idController : _emailController))),
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
                          : _buildForm("ID"),
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
