import 'package:chat_app/Screens/HomeScreen/homescreen.dart';
import 'package:chat_app/Widgets/ktextformfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class UserDetailFormScreen extends StatefulWidget {
  UserDetailFormScreen({Key? key, required this.user}) : super(key: key);

  final User user;

  static String routeName = '/userDetailInput';

  @override
  State<UserDetailFormScreen> createState() => _UserDetailFormScreenState();
}

class _UserDetailFormScreenState extends State<UserDetailFormScreen> {
  bool isLoading = false;
  final TextEditingController _nameController = TextEditingController();

  var users = FirebaseFirestore.instance.collection("Users");
  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  _validateInputField() {
    return _formKey.currentState!.validate();
  }

  Future<void> _save({required String name, required String email}) async {
    setState(() {
      isLoading = true;
    });
    await widget.user.updateDisplayName(name);
    await users.doc(widget.user.phoneNumber.toString()).set({
      "name": name,
      "phonenumber": widget.user.phoneNumber,
      "uid": widget.user.uid,
      "lastseen": '',
      "status": "offline",
      "email": email,
      "profile":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/head-659652_960_720.png",
    });
    await widget.user.updateEmail(email);
    print(email);
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
        title: const Text("Please Enter Details"),
      ),
      body: Container(
        padding: const EdgeInsets.all(30),
        child: Form(
            key: _formKey,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      kTextFormFieldWidget(
                        controller: _nameController,
                        lable: "Username",
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      kTextFormFieldWidget(
                          controller: _emailController,
                          lable: "Email Adress",
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (value) {
                            bool _isValid = _validateInputField();
                            if (_isValid) {
                              _save(
                                      name: _nameController.text,
                                      email: _emailController.text)
                                  .then((value) {
                                Navigator.pushNamedAndRemoveUntil(context,
                                    HomeScreen.routeName, (route) => false);
                              });
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter Email Adress";
                            } else if (!RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                .hasMatch(value)) {
                              return 'Enter a valid email!';
                            }
                            return null;
                          }),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    onTap: () {
                      bool _isValid = _validateInputField();
                      if (_isValid) {
                        _save(
                                name: _nameController.text,
                                email: _emailController.text)
                            .then((value) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, HomeScreen.routeName, (route) => false);
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text(
                        "SUBMIT",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      )),
                    ),
                  ),
                ),
                Align(
                  child: isLoading
                      ? Container(child: const CircularProgressIndicator())
                      : Container(),
                ),
              ],
            )),
      ),
    );
  }
}
