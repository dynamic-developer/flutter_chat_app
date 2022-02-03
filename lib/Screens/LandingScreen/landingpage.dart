import 'package:chat_app/Screens/HomeScreen/homescreen.dart';
import 'package:chat_app/Screens/LoginScreen/loginscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  static String routeName = '/';

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print("currently signed out!!");
        Navigator.pushNamedAndRemoveUntil(
            context, LoginScreen.routeName, (route) => false);
      } else {
        print("User signed in");
        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: Color(0xff002b5c),
      body: Center(
        child: Hero(
          tag: 'first',
          child: Container(
            height: 200,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
