// ignore_for_file: avoid_print, prefer_is_empty

import 'package:chat_app/Screens/GroupChatScreen/groupchatscreen.dart';
import 'package:chat_app/Widgets/ktextformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AvailableGroupScreenArgs {
  AvailableGroupScreenArgs({required this.user});

  final User user;
}

class AvailableGroupScreen extends StatefulWidget {
  static String routeName = '/groupScreen';
  AvailableGroupScreen({Key? key}) : super(key: key);

  @override
  State<AvailableGroupScreen> createState() => _AvailableGroupScreenState();
}

class _AvailableGroupScreenState extends State<AvailableGroupScreen> {
  final _dbRef = FirebaseFirestore.instance;

  Future _createGroup(
      {required String groupName, required String groupOwnerNumber}) async {
    DocumentReference _doc = _dbRef.collection("Groups").doc();
    String _docId = _doc.id;

    await _doc.set({
      "group_name": groupName,
      "group_owner": groupOwnerNumber,
      "created_at": DateTime.now().millisecondsSinceEpoch.toString(),
      "id": _docId,
      "group_members": [groupOwnerNumber],
    });
  }

  Future<List<QueryDocumentSnapshot>> _future(
      {required String userNumber}) async {
    var documentSnapshot =
        await _dbRef.collection('Users').doc(userNumber).get();
    List<QueryDocumentSnapshot> result = [];
    if (documentSnapshot.exists) {
      result = await _dbRef.collection("Groups").get().then((value) {
        return value.docs.where((element) {
          return (element.data()["group_members"] as List).contains(userNumber);
        }).toList();
      });
    }
    print(userNumber);
    return result;
  }

  final TextEditingController _groupNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    AvailableGroupScreenArgs _args =
        ModalRoute.of(context)!.settings.arguments as AvailableGroupScreenArgs;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              isScrollControlled: true,
              enableDrag: true,
              context: context,
              builder: (contx) {
                return Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(20))),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      children: [
                        kTextFormFieldWidget(
                          controller: _groupNameController,
                          lable: "Enter Group Name",
                          maxLength: 20,
                        ),
                        TextButton(
                          onPressed: () {
                            if (_groupNameController.text.length != 0) {
                              _createGroup(
                                      groupName: _groupNameController.text,
                                      groupOwnerNumber:
                                          _args.user.phoneNumber.toString())
                                  .then((val) {
                                Navigator.pop(context);
                              });
                            }
                          },
                          child: const Text("Create"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).then((value) {
            _groupNameController.clear();
            setState(() {});
          });
        },
        label: const Text("Create Group"),
        extendedIconLabelSpacing: 10,
        icon: const Icon(Icons.group_add),
      ),
      appBar: AppBar(
        title: const Text("Groups"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _future(userNumber: _args.user.phoneNumber!),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              print(snapshot.data.toString());
              if (snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final docSnapshot = snapshot.data![index].data();

                    return GroupWidget(
                      groupName: docSnapshot['group_name'],
                      onTap: () {
                        print(docSnapshot['group_owner']);
                        Navigator.of(context).pushNamed(
                            GroupChatScreen.routeName,
                            arguments: GroupChatScreenArgs(
                              currentNumber: _args.user.phoneNumber.toString(),
                              groupId: docSnapshot["id"],
                              groupName: docSnapshot['group_name'],
                            ));
                        // print(docSnapshot["uid"]);
                      },
                    );
                  },
                );
              } else {
                return const Center(
                  child: Text("No Group Available"),
                );
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}

class GroupWidget extends StatelessWidget {
  const GroupWidget({
    Key? key,
    required this.groupName,
    this.onTap,
  }) : super(key: key);

  final String groupName;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[300],
          child: Text(
            groupName[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        enableFeedback: true,
        title: Text(groupName),
      ),
    );
  }
}
