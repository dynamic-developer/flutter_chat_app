import 'package:chat_app/Screens/AvailableUserScreen/availableuserscreen.dart';
import 'package:chat_app/Screens/LoginScreen/loginscreen.dart';
import 'package:chat_app/Screens/UserDetilFormScreen/userdetailformscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/home';

  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setStatus("online");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("online");
    } else {
      print("------------------------------------");
      setStatus("offline");
    }
  }

  void setStatus(String status) async {
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.phoneNumber)
        .update({
      "status": status,
      "lastseen": Timestamp.now().millisecondsSinceEpoch.toString()
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.displayName != null) {
        return AvailableUserScreen();
      } else {
        return UserDetailFormScreen(
          user: user,
        );
      }
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
