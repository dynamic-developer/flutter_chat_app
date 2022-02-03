import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({Key? key, required this.id}) : super(key: key);

  final String id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("Users").doc(id).get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var data = snapshot.data!.data();
              return Container(
                margin: const EdgeInsets.all(20),
                child: SafeArea(
                  child: Column(
                    children: [
                      Hero(
                        tag: "${data!["profile"] + data['name']}",
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              CachedNetworkImageProvider(data["profile"]),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text(data['name']),
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
                    ],
                  ),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
