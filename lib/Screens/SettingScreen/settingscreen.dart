import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/LoginScreen/loginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SettingScreen extends StatefulWidget {
  SettingScreen({Key? key}) : super(key: key);
  static String routeName = '/settings';

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late File imageFile;
  bool isLoading = false;
  TextEditingController _controller = TextEditingController();

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } catch (e) {
      // ignore: todo
      print(e); // TODO: show dialog with error
    }
  }

  Future _getImage({required String id}) async {
    setState(() {
      isLoading = true;
    });
    ImagePicker _picker = ImagePicker();
    await _picker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        imageFile = File(value.path);
        uploadImage(id: id);
      }
    });
  }

  Future uploadImage({required String id}) async {
    String fileName = const Uuid().v1();
    var ref =
        FirebaseStorage.instance.ref().child("images").child("$fileName.jpg");
    var uploadT = await ref.putFile(imageFile);
    String url = await uploadT.ref.getDownloadURL();
    debugPrint(url);
    await FirebaseFirestore.instance.collection("Users").doc(id).update({
      "profile": url,
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: const Text("Settings"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("Users")
              .doc(FirebaseAuth.instance.currentUser!.phoneNumber)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Map<String, dynamic> data = snapshot.data!.data()!;
              return SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 60,
                            child:
                                isLoading ? CircularProgressIndicator() : null,
                            backgroundImage: CachedNetworkImageProvider(
                              data["profile"],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: () => _getImage(id: data["phonenumber"]),
                              child: const CircleAvatar(
                                backgroundColor: Colors.indigoAccent,
                                child: Icon(
                                  Icons.camera_alt,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 30),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: TextFormField(
                          decoration: InputDecoration(border: InputBorder.none),
                          // controller: _controller,
                          initialValue: data["name"],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (newValue) async {
                            print("SUBMIT::: $newValue");
                            if (newValue.length != 0) {
                              if (newValue != data["name"]) {
                                print("aaaaaa");
                                await FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(data['phonenumber'])
                                    .update({
                                  "name": newValue,
                                });
                              }
                            }
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.call),
                        title:
                            Text(data['phonenumber'].toString().substring(3)),
                      ),
                      ListTile(
                        leading: Icon(Icons.email),
                        title: Text(data['email']),
                      ),
                      ListTile(
                        onTap: () => _signOut(context),
                        leading: Icon(Icons.logout),
                        title: Text("Log Out"),
                      )
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}
