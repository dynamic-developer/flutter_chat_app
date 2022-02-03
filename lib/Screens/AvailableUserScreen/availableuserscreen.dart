// ignore_for_file: avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/AvailableGroupScreen/availablegroupscreen.dart';
import 'package:chat_app/Screens/ChatScreen/chatscreen.dart';
import 'package:chat_app/Screens/LoginScreen/loginscreen.dart';
import 'package:chat_app/Screens/SettingScreen/settingscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class AvailableUserScreen extends StatefulWidget {
  const AvailableUserScreen({Key? key}) : super(key: key);

  @override
  State<AvailableUserScreen> createState() => _AvailableUserScreenState();
}

class _AvailableUserScreenState extends State<AvailableUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;

  Future<List<QueryDocumentSnapshot>> _future() async {
    List<Contact> contacts = [];
    var ref = _firestore.collection("Users");
    List<QueryDocumentSnapshot> result = [];

    if (await FlutterContacts.requestPermission()) {
      debugPrint("::: USER HAS PERMISSION TO ACCESS CONTACTS :::");
      contacts = await FlutterContacts.getContacts(withProperties: true);
      debugPrint("::: CONTACTS READ FROM DEVICE :::");
      print(contacts[0]);
      List<String> numbers = contacts.map((e) {
        String n = e.phones.first.number.replaceAll(RegExp('[^0-9]'), '');
        debugPrint("::: NUMBER $n :::");

        return "+91${n.substring(n.length - 10)}";
      }).toList();
      debugPrint(":::TOTAL CONTACTS ${numbers.length}");
      result = await ref.get().then((value) {
        return value.docs.where((element) {
          if (element.id != _currentUser!.phoneNumber) {
            return numbers.contains(element.id);
          }
          return false;
        }).toList();
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AvailableGroupScreen.routeName,
              arguments: AvailableGroupScreenArgs(user: _currentUser!));
        },
        label: const Text("Group chat"),
        extendedIconLabelSpacing: 10,
        icon: const Icon(Icons.group),
      ),
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: const Text("ChatApp"),
        actions: <Widget>[
          TextButton(
            child: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, SettingScreen.routeName);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _future(),
          builder: (context, snapshot) {
            if (snapshot.hasData && _currentUser != null) {
              if (snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final docSnapshot = snapshot.data![index].data();

                    return ContactWidget(
                      profileUrl: docSnapshot['profile'],
                      contactName: docSnapshot['name'],
                      onTap: () {
                        print(docSnapshot['phonenumber']);
                        Navigator.of(context).pushNamed(ChatScreen.routeName,
                            arguments: ChatScreenArgs(
                                profileUrl: docSnapshot['profile'],
                                currentNumber:
                                    _currentUser!.phoneNumber.toString(),
                                toNumber: docSnapshot['phonenumber'],
                                toName: docSnapshot['name']));
                        print(docSnapshot["uid"]);
                      },
                    );
                  },
                );
              } else {
                return const Center(
                  child: Text("No Contacts Available"),
                );
              }
            } else {
              FlutterContacts.requestPermission().then((value) {});
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}

class ContactWidget extends StatelessWidget {
  const ContactWidget(
      {Key? key,
      required this.contactName,
      this.onTap,
      this.contactNumber,
      this.isAdmin,
      this.profileUrl,
      this.isSelected = false})
      : super(key: key);
  final String? profileUrl;
  final String contactName;
  final String? contactNumber;
  final bool isSelected;
  final bool? isAdmin;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : null,
          borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        tileColor: isSelected ? Colors.indigo : null,
        subtitle: contactNumber == null ? null : Text(contactNumber!),
        onTap: onTap,
        leading: Hero(
          tag: "${profileUrl! + contactName}",
          child: CircleAvatar(
            backgroundImage: profileUrl != null
                ? CachedNetworkImageProvider(profileUrl!)
                : null,
            child: profileUrl == null
                ? Text(
                    contactName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
        ),
        trailing: isAdmin == true
            ? const Text(
                "Admin",
                style: TextStyle(color: Colors.redAccent),
              )
            : null,
        enableFeedback: true,
        title: Text(
          contactName,
          style: TextStyle(
            color: isSelected ? Colors.indigo.shade100 : Colors.black,
          ),
        ),
      ),
    );
  }
}
