// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Const/functions.dart';
import 'package:chat_app/Screens/AvailableUserScreen/availableuserscreen.dart';
import 'package:chat_app/Screens/ImageScreen/imagescreen.dart';
import 'package:chat_app/Widgets/kvideoplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class GroupChatScreenArgs {
  final String groupId;
  final String groupName;
  final String currentNumber;
  GroupChatScreenArgs({
    required this.groupId,
    required this.currentNumber,
    required this.groupName,
  });
}

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({Key? key}) : super(key: key);
  static String routeName = '/groupChatScreen';

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  TextEditingController textEditingController = TextEditingController();

  late List<DocumentSnapshot> listMessage;
  List<DateTime> listDay = [];
  List<String> selectedContacts = [];
  late String groupAdminNumber;
  final ScrollController listScrollController = ScrollController();

  final _groupsDbRef = FirebaseFirestore.instance.collection('Groups');
  final _userDbRef = FirebaseFirestore.instance.collection("Users");

  File? imageFile;
  File? videoFile;

  Future _getVideo({required String id, required String groupId}) async {
    ImagePicker _picker = ImagePicker();
    await _picker
        .pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 20))
        .then((value) async {
      if (value != null) {
        videoFile = File(value.path);
        print(":::Video File Name : ${videoFile!.path}");
        uploadVideo(id: id, groupId: groupId);
      }
    });

    // await _playVideo(file);
  }

  Future uploadVideo({required String id, required String groupId}) async {
    String fileName = const Uuid().v1();
    String fileExtansion = videoFile!.uri
        .toString()
        .substring(videoFile!.uri.toString().lastIndexOf("."))
        .toString();
    print("FILE EXTENSION : " + fileExtansion);
    var ref = FirebaseStorage.instance
        .ref()
        .child("videos")
        .child(fileName + fileExtansion);
    var uploadT = await ref.putFile(
        videoFile!, SettableMetadata(contentType: 'video/mp4'));
    String url = await uploadT.ref.getDownloadURL();
    debugPrint(url);
    await _onSendMessage(
        content: url, senderId: id, groupId: groupId, contentType: "video");
  }

  Future _getImage({required String id, required String groupId}) async {
    ImagePicker _picker = ImagePicker();
    await _picker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        imageFile = File(value.path);
        uploadImage(id: id, groupId: groupId);
      }
    });
  }

  Future uploadImage({required String id, required String groupId}) async {
    String fileName = const Uuid().v1();
    var ref =
        FirebaseStorage.instance.ref().child("images").child("$fileName.jpg");
    var uploadT = await ref.putFile(imageFile!);
    String url = await uploadT.ref.getDownloadURL();
    debugPrint(url);
    await _onSendMessage(
        content: url, senderId: id, contentType: "img", groupId: groupId);
  }

  Future _onSendMessage({
    required String content,
    String contentType = 'text',
    required String senderId,
    required String groupId,
  }) async {
    if (content.trim() != '') {
      textEditingController.clear();
      content = content.trim();
      await _groupsDbRef.doc(groupId).collection("Messages").add({
        "content": content,
        "contenttype": contentType,
        'idFrom': senderId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      // Database.sendMessage(convoID, uid, contact.id, content,
      //     DateTime.now().millisecondsSinceEpoch.toString());
      listScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<String> _getAdminNumber(groupId) async {
    late String admin;
    await _groupsDbRef.doc(groupId).get().then((value) {
      admin = value.data()!["group_owner"];
    });
    return admin;
  }

  Future<Map<String, List<QueryDocumentSnapshot>>> _getGroupMembers(
      currentNumber, groupId) async {
    List<QueryDocumentSnapshot> result = [];
    List<QueryDocumentSnapshot> contactList = [];
    var groupMembers = [];
    List<Contact> contacts = [];
    List<QueryDocumentSnapshot> currentUser = [];

    await _groupsDbRef.doc(groupId).get().then((documentSnapshot) {
      groupMembers = documentSnapshot.data()!["group_members"];
    });

    if (await FlutterContacts.requestPermission()) {
      contacts = await FlutterContacts.getContacts(withProperties: true);

      List<String> numbers = contacts.map((e) {
        String n = e.phones.first.number.replaceAll(RegExp('[^0-9]'), '');

        return "+91${n.substring(n.length - 10)}";
      }).toList();
      await _userDbRef.get().then((value) {
        return value.docs.where((element) {
          if (element.id == currentNumber) {
            currentUser.add(element);
            return false;
          } else {
            if (groupMembers.contains(element.id)) {
              print("oooooooooooooooooooooo");
              if (numbers.contains(element.id)) {
                contactList.add(element);
              } else {
                result.add(element);
              }
              return groupMembers.contains(element.id);
            }
            return false;
          }
        }).toList();
      });
    }

    print("GROUPMEMBERS : $groupMembers");
    return {
      "saved_contacts": contactList,
      "unsaved_contacts": result,
      "current_user": currentUser
    };
  }

  Future<List<QueryDocumentSnapshot>> _future(currentNumber, groupId) async {
    List<Contact> contacts = [];
    var groupMembers = [];
    List<QueryDocumentSnapshot> result = [];

    await _groupsDbRef.doc(groupId).get().then((documentSnapshot) {
      groupMembers = documentSnapshot.data()!["group_members"];
    });

    if (await FlutterContacts.requestPermission()) {
      contacts = await FlutterContacts.getContacts(withProperties: true);

      List<String> numbers = contacts.map((e) {
        String n = e.phones.first.number.replaceAll(RegExp('[^0-9]'), '');

        return "+91${n.substring(n.length - 10)}";
      }).toList();

      result = await _userDbRef.get().then((value) {
        return value.docs.where((element) {
          if (element.id != currentNumber) {
            if (!groupMembers.contains(element.id)) {
              return numbers.contains(element.id);
            }
          }
          return false;
        }).toList();
      });
    }
    return result;
  }

  Future _AddMembersToGroup(
      List<String> phoneNumberList, String groupId) async {
    List groupMembers = [];
    await _groupsDbRef.doc(groupId).get().then((documentSnapshot) {
      groupMembers = documentSnapshot.data()!["group_members"];
    });

    await _groupsDbRef.doc(groupId).update({
      "group_members": [...groupMembers, ...phoneNumberList]
    });
  }

  @override
  Widget build(BuildContext context) {
    GroupChatScreenArgs _args =
        ModalRoute.of(context)!.settings.arguments as GroupChatScreenArgs;
    _getAdminNumber(_args.groupId).then((val) {
      groupAdminNumber = val;
    });
    return Scaffold(
        appBar: AppBar(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _args.groupName,
              ),
              const SizedBox(width: 5),
              // FutureBuilder<String>(
              //   future: _getStatusDetails(_args.toNumber),
              //   builder: (context, snapshot) {
              //     print("Snapshot: " + snapshot.hasData.toString());
              //     if (snapshot.hasData) {
              //       String res = snapshot.data!;
              //       if (res.length != 0) {
              //         if (res == "online") {
              //           return const Text(
              //             "Online",
              //             style: TextStyle(
              //               fontSize: 12,
              //             ),
              //           );
              //         } else {
              //           return Text(
              //             "Last Seen at ${DateTime.fromMillisecondsSinceEpoch(int.parse(res)).hour.toString()}:${DateTime.fromMillisecondsSinceEpoch(int.parse(res)).minute.toString()}",
              //             style: const TextStyle(
              //               fontSize: 12,
              //             ),
              //           );
              //         }
              //       } else {
              //         return const Text(
              //           "Offline",
              //           style: TextStyle(
              //             fontSize: 12,
              //           ),
              //         );
              //       }
              //     } else {
              //       return Container(
              //         height: 20,
              //         width: 20,
              //         child: CircularProgressIndicator(
              //           color: Colors.white,
              //         ),
              //       );
              //     }
              //   },
              // )
            ],
          ),
          actions: [
            IconButton(
                onPressed: () {
                  print(_args.currentNumber);

                  showModalBottomSheet(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      context: context,
                      enableDrag: true,
                      isScrollControlled: true,
                      builder: (conxt) {
                        return StatefulBuilder(builder: (context, setState) {
                          return Padding(
                            padding: MediaQuery.of(conxt).viewInsets,
                            child: SizedBox(
                              height: MediaQuery.of(conxt).size.height / 2,
                              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                                  future: _future(
                                      _args.currentNumber, _args.groupId),
                                  builder: (conxt, snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data!.isNotEmpty) {
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          children: [
                                            ListTile(
                                              title: const Text("Select Users"),
                                              subtitle: selectedContacts
                                                      .isNotEmpty
                                                  ? Text(
                                                      "${selectedContacts.length} user selectd")
                                                  : null,
                                              trailing: IconButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  icon:
                                                      const Icon(Icons.cancel)),
                                            ),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: snapshot.data!.length,
                                              itemBuilder: (conxt, index) {
                                                final docSnapshot = snapshot
                                                    .data![index]
                                                    .data();
                                                String phoneNumber =
                                                    docSnapshot['phonenumber'];
                                                return ContactWidget(
                                                  profileUrl:
                                                      docSnapshot['profile'],
                                                  isSelected: selectedContacts
                                                      .contains(phoneNumber),
                                                  contactName:
                                                      docSnapshot['name'],
                                                  onTap: () {
                                                    print(phoneNumber);
                                                    if (selectedContacts
                                                        .contains(
                                                            phoneNumber)) {
                                                      selectedContacts
                                                          .remove(phoneNumber);
                                                    } else {
                                                      selectedContacts
                                                          .add(phoneNumber);
                                                    }
                                                    setState(() {});

                                                    // Navigator.of(context).pushNamed(
                                                    //     ChatScreen.routeName,
                                                    //     arguments: ChatScreenArgs(
                                                    //         currentNumber: _currentUser!
                                                    //             .phoneNumber
                                                    //             .toString(),
                                                    //         toNumber: docSnapshot[
                                                    //             'phonenumber'],
                                                    //         toName: docSnapshot['name']));
                                                    // print(docSnapshot["uid"]);
                                                  },
                                                );
                                              },
                                            ),
                                            selectedContacts.isNotEmpty
                                                ? TextButton(
                                                    onPressed: () {
                                                      print(selectedContacts);
                                                      _AddMembersToGroup(
                                                              selectedContacts,
                                                              _args.groupId)
                                                          .then((value) {
                                                        Navigator.pop(context);
                                                      });
                                                    },
                                                    child: const Text("Add"))
                                                : Container()
                                          ],
                                        );
                                      } else {
                                        return const Center(
                                          child: Text("No Contacts Available"),
                                        );
                                      }
                                    } else {
                                      FlutterContacts.requestPermission()
                                          .then((value) {});
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  }),
                            ),
                          );
                        });
                      }).then((value) {
                    selectedContacts.clear();
                  });
                },
                icon: const Icon(Icons.person_add)),
            IconButton(
              onPressed: () {
                print(_args.currentNumber);
                showModalBottomSheet(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    context: context,
                    enableDrag: true,
                    isScrollControlled: true,
                    builder: (conxt) {
                      return Padding(
                        padding: MediaQuery.of(conxt).viewInsets,
                        child: SizedBox(
                          height: MediaQuery.of(conxt).size.height / 2,
                          child: FutureBuilder<
                                  Map<String, List<QueryDocumentSnapshot>>>(
                              future: _getGroupMembers(
                                  _args.currentNumber, _args.groupId),
                              builder: (conxt, snapshot) {
                                if (snapshot.hasData) {
                                  if (snapshot.data!.isNotEmpty) {
                                    final currentUserData = snapshot
                                        .data!["current_user"]![0]
                                        .data();
                                    print(
                                        "CONTACTS : ${snapshot.data!["group_members"]}");
                                    return ListView(
                                      shrinkWrap: true,
                                      // alignment: WrapAlignment.center,
                                      children: [
                                        ListTile(
                                          title: const Text("Group Members"),
                                          subtitle: Text(
                                              "Total Members ${((snapshot.data?["saved_contacts"]?.length) ?? 0) + 1 + ((snapshot.data!["unsaved_contacts"]?.length) ?? 0)}"),
                                          trailing: IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(Icons.cancel)),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: snapshot
                                              .data!["saved_contacts"]!.length,
                                          itemBuilder: (conxt, index) {
                                            final docSnapshot = snapshot
                                                .data!["saved_contacts"]![index]
                                                .data();
                                            String phoneNumber =
                                                docSnapshot['phonenumber'];
                                            // return Text(
                                            //     docSnapshot["phonenumber"]);

                                            return ContactWidget(
                                              profileUrl:
                                                  docSnapshot['profile'],
                                              isAdmin: phoneNumber ==
                                                  groupAdminNumber,
                                              contactName: docSnapshot['name'],
                                              onTap: () {
                                                print(phoneNumber);
                                                if (selectedContacts
                                                    .contains(phoneNumber)) {
                                                  selectedContacts
                                                      .remove(phoneNumber);
                                                } else {
                                                  selectedContacts
                                                      .add(phoneNumber);
                                                }
                                                setState(() {});

                                                // Navigator.of(context).pushNamed(
                                                //     ChatScreen.routeName,
                                                //     arguments: ChatScreenArgs(
                                                //         currentNumber: _currentUser!
                                                //             .phoneNumber
                                                //             .toString(),
                                                //         toNumber: docSnapshot[
                                                //             'phonenumber'],
                                                //         toName: docSnapshot['name']));
                                                // print(docSnapshot["uid"]);
                                              },
                                            );
                                          },
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: snapshot
                                              .data!["unsaved_contacts"]!
                                              .length,
                                          itemBuilder: (conxt, index) {
                                            final docSnapshot = snapshot.data![
                                                    "unsaved_contacts"]![index]
                                                .data();
                                            String phoneNumber =
                                                docSnapshot['phonenumber'];
                                            // return Text(
                                            //     docSnapshot["phonenumber"]);

                                            return ContactWidget(
                                              profileUrl:
                                                  docSnapshot['profile'],
                                              isAdmin: phoneNumber ==
                                                  groupAdminNumber,
                                              contactName: prettifyPhonenumber(
                                                  phonenumber: phoneNumber),
                                              onTap: () {
                                                // Navigator.of(context).pushNamed(
                                                //     ChatScreen.routeName,
                                                //     arguments: ChatScreenArgs(
                                                //         currentNumber: _currentUser!
                                                //             .phoneNumber
                                                //             .toString(),
                                                //         toNumber: docSnapshot[
                                                //             'phonenumber'],
                                                //         toName: docSnapshot['name']));
                                                // print(docSnapshot["uid"]);
                                              },
                                            );
                                          },
                                        ),
                                        ContactWidget(
                                          profileUrl:
                                              currentUserData['profile'],
                                          contactName: "You",
                                          isAdmin: _args.currentNumber ==
                                              groupAdminNumber,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return const Center(
                                      child: Text("No Contacts Available"),
                                    );
                                  }
                                } else {
                                  FlutterContacts.requestPermission()
                                      .then((value) {});
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                              }),
                        ),
                      );
                    }).then((value) {});
              },
              icon: const Icon(Icons.more_vert),
            )
          ],
        ),
        body: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: StreamBuilder<QuerySnapshot>(
                stream: _groupsDbRef
                    .doc(_args.groupId)
                    .collection("Messages")
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  print("GROUP ID: ${_args.groupId}");
                  print("SNAPSHOT DATA: ${snapshot.data?.docs}");
                  if (snapshot.hasData) {
                    listMessage = snapshot.data!.docs;
                    if (listMessage.isEmpty) {
                      return const Center(
                        child: Text(
                          "Start Conversations",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    listMessage.sort((b, a) =>
                        DateTime.fromMillisecondsSinceEpoch(
                                int.parse(a['timestamp']))
                            .toString()
                            .compareTo(DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(b['timestamp']))
                                .toString()));

                    for (var e in listMessage) {
                      // print(DateTime.tryParse(e['timestamp']));
                      DateTime day = DateTime.fromMillisecondsSinceEpoch(
                          int.parse(e['timestamp']));
                      if (!listDay.contains(day)) {
                        listDay.add(DateTime.fromMillisecondsSinceEpoch(
                            int.parse(e['timestamp'])));
                      }
                    }
                    return GroupedListView<DocumentSnapshot, String>(
                      controller: listScrollController,
                      elements: listMessage,
                      reverse: true,
                      sort: false,
                      floatingHeader: true,
                      // order: GroupedListOrder.DESC,
                      useStickyGroupSeparators: true,
                      groupBy: (element) {
                        var msgDate = Timestamp.fromMillisecondsSinceEpoch(
                                int.parse(element['timestamp']))
                            .toDate();
                        return DateFormat('EEE, d/M/y').format(msgDate);
                      },
                      groupHeaderBuilder: (e) => SizedBox(
                        height: 35,
                        child: Align(
                          child: Container(
                            // ignore: prefer_const_constructors
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10.0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                getDayFromDate(
                                    curruntTime: DateTime.now(),
                                    msgTime:
                                        Timestamp.fromMillisecondsSinceEpoch(
                                                int.parse(e['timestamp']))
                                            .toDate()),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      itemBuilder: (context, document) {
                        print(document.id);
                        var msgDate = Timestamp.fromMillisecondsSinceEpoch(
                                int.parse(document['timestamp']))
                            .toDate();
                        var msgTime = DateFormat('hh:mm a').format(msgDate);
                        // if (!document['read'] &&
                        //     document['idTo'] == _args.currentNumber) {
                        //   _updateMessageRead(document, document.id);
                        // }
                        if (document['idFrom'] == _args.currentNumber) {
                          // debugPrint(":hi : ${msgTime}");
                          return Row(
                            key: Key(DateTime.now()
                                .millisecondsSinceEpoch
                                .toString()),
                            children: [
                              Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Bubble(
                                    color: Colors.indigo.shade600,
                                    style: const BubbleStyle(
                                        padding: BubbleEdges.all(0)),
                                    elevation: 5,
                                    padding: const BubbleEdges.all(10.0),
                                    nip: BubbleNip.rightTop,
                                    child: document['contenttype'] == "text"
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 50,
                                                          maxWidth: 85),
                                                  child: Text(
                                                    document['content'],
                                                    maxLines: 5,
                                                    style: const TextStyle(
                                                      overflow:
                                                          TextOverflow.visible,
                                                      color: Colors.white,
                                                    ),
                                                  )),
                                              Row(
                                                children: [
                                                  Text(
                                                    msgTime,
                                                    // ignore: prefer_const_constructors
                                                    style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 10),
                                                  ),
                                                  // Icon(
                                                  //   Icons.check,
                                                  //   size: 12,
                                                  //   color: document['read']
                                                  //       ? Colors.green
                                                  //       : Colors.white60,
                                                  // ),
                                                ],
                                              )
                                            ],
                                          )
                                        : document['contenttype'] == "video"
                                            ? Stack(
                                                children: [
                                                  KVideoPlayer(
                                                      videoPlayerController:
                                                          VideoPlayerController
                                                              .network(document[
                                                                  'content'])),
                                                  Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            msgTime,
                                                            // ignore: prefer_const_constructors
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white60,
                                                                fontSize: 10),
                                                          ),
                                                        ],
                                                      )),
                                                ],
                                              )
                                            : InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ImageScreen(
                                                              url: document[
                                                                  'content']),
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl:
                                                          document['content'],
                                                      fit: BoxFit.cover,
                                                      progressIndicatorBuilder:
                                                          (context, url,
                                                                  downloadProgress) =>
                                                              Center(
                                                        child: SizedBox(
                                                          height: 60,
                                                          width: 60,
                                                          child: CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              value:
                                                                  downloadProgress
                                                                      .progress),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                          url, error) {
                                                        debugPrint(error);
                                                        return const Icon(Icons
                                                            .image_search_rounded);
                                                      },
                                                    ),
                                                    Positioned(
                                                        bottom: 0,
                                                        right: 0,
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              msgTime,
                                                              // ignore: prefer_const_constructors
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white60,
                                                                  fontSize: 10),
                                                            ),
                                                            // Icon(
                                                            //   Icons.check,
                                                            //   size: 12,
                                                            //   color:
                                                            //       document['read']
                                                            //           ? Colors.green
                                                            //           : Colors
                                                            //               .white60,
                                                            // ),
                                                          ],
                                                        )),
                                                  ],
                                                ),
                                              ),
                                  ),
                                  width: 200)
                            ],
                            mainAxisAlignment: MainAxisAlignment.end,
                          );
                        } else {
                          String phoneNumber = document["idFrom"].toString();
                          phoneNumber =
                              prettifyPhonenumber(phonenumber: phoneNumber);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(children: <Widget>[
                              Container(
                                child: Bubble(
                                  color: Colors.indigo.shade300,
                                  elevation: 5,
                                  padding: const BubbleEdges.all(5.0),
                                  nip: BubbleNip.leftTop,
                                  child: document['contenttype'] == "text"
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    phoneNumber,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 50,
                                                            maxWidth: 85),
                                                    child: Text(
                                                      document['content'],
                                                      maxLines: 5,
                                                      style: const TextStyle(
                                                          overflow: TextOverflow
                                                              .visible,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              msgTime,
                                              // ignore: prefer_const_constructors
                                              style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 10),
                                            )
                                          ],
                                        )
                                      : document['contenttype'] == "video"
                                          ? Stack(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      phoneNumber,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    KVideoPlayer(
                                                        videoPlayerController:
                                                            VideoPlayerController
                                                                .network(document[
                                                                    'content'])),
                                                  ],
                                                ),
                                                Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          msgTime,
                                                          // ignore: prefer_const_constructors
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white60,
                                                              fontSize: 10),
                                                        ),
                                                      ],
                                                    )),
                                              ],
                                            )
                                          : InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageScreen(
                                                            url: document[
                                                                'content']),
                                                  ),
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        phoneNumber,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      CachedNetworkImage(
                                                        imageUrl:
                                                            document['content'],
                                                        fit: BoxFit.cover,
                                                        progressIndicatorBuilder:
                                                            (context, url,
                                                                    downloadProgress) =>
                                                                Center(
                                                          child: SizedBox(
                                                            height: 60,
                                                            width: 60,
                                                            child: CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                value: downloadProgress
                                                                    .progress),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                            url, error) {
                                                          debugPrint(error);
                                                          return const Icon(Icons
                                                              .image_search_rounded);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: Text(
                                                      msgTime,
                                                      // ignore: prefer_const_constructors
                                                      style: TextStyle(
                                                          color: Colors.white60,
                                                          fontSize: 10),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                ),
                                width: 200.0,
                                margin: const EdgeInsets.only(left: 10.0),
                              )
                            ]),
                          );
                        }
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
                child: Row(
                  children: [
                    Flexible(
                        child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade300,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: TextField(
                              autofocus: true,
                              maxLines: 3,
                              minLines: 1,
                              style: const TextStyle(color: Colors.white70),
                              controller: textEditingController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: const BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                                hintStyle:
                                    const TextStyle(color: Colors.white70),
                                hintText: 'Message...',
                              ),
                            ),
                          ),
                          InkWell(
                              onTap: () {
                                debugPrint("Add Image");
                                _getImage(
                                    id: _args.currentNumber,
                                    groupId: _args.groupId);
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white70,
                                  ))),
                          InkWell(
                              onTap: () {
                                debugPrint("Add Video");
                                _getVideo(
                                  id: _args.currentNumber,
                                  groupId: _args.groupId,
                                );
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: const Icon(
                                    Icons.video_call,
                                    color: Colors.white70,
                                    size: 28,
                                  ))),
                        ],
                      ),
                    )),
                    const SizedBox(
                      width: 5,
                    ),
                    InkWell(
                      onTap: () {
                        _onSendMessage(
                          content: textEditingController.text,
                          groupId: _args.groupId,
                          senderId: _args.currentNumber,
                        );
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: Colors.indigo.shade300,
                            borderRadius: BorderRadius.circular(40)),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
