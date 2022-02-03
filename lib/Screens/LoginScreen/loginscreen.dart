import 'package:chat_app/Screens/HomeScreen/homescreen.dart';
import 'package:chat_app/Screens/LandingScreen/landingpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      Navigator.pushNamedAndRemoveUntil(
          context, HomeScreen.routeName, (r) => false);
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _phoneNumber = "0";

  Future registerUser(String phone, BuildContext context) async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (AuthCredential credential) async {
          UserCredential result = await _auth.signInWithCredential(credential);
          User? user = result.user;
          if (user != null) {
            Navigator.pushNamedAndRemoveUntil(
                context, HomeScreen.routeName, (r) => false);
          } else {
            print("Error");
          }
        },
        verificationFailed: (FirebaseAuthException authException) {
          print(authException.message);
        },
        codeSent: (verificationId, forceResendingToken) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Enter the OTP?"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      maxLength: 6,
                      controller: _codeController,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text("Confirm"),
                    onPressed: () async {
                      FirebaseAuth auth = FirebaseAuth.instance;
                      final code = _codeController.text.trim();

                      AuthCredential credential = PhoneAuthProvider.credential(
                          verificationId: verificationId, smsCode: code);

                      UserCredential result =
                          await _auth.signInWithCredential(credential);

                      User? user = result.user;

                      if (user != null) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, HomeScreen.routeName, (r) => false);
                      } else {
                        print("Error");
                      }
                    },
                  )
                ],
              );
            },
          ).then((value) {
            _codeController.clear();
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationId = verificationId;
          print(verificationId);
          print("Timout");
        });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 5, bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InternationalPhoneNumberInput(
                  selectorTextStyle: const TextStyle(color: Colors.white),
                  textStyle: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  formatInput: false,
                  inputDecoration: const InputDecoration(
                    hintText: "Phone number",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                  countries: ['IN', "US"],
                  initialValue: PhoneNumber(isoCode: 'IN'),
                  selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET),
                  maxLength: 10,
                  textFieldController: _controller,
                  ignoreBlank: true,
                  spaceBetweenSelectorAndTextField: 0,
                  autoValidateMode: AutovalidateMode.disabled,
                  onInputValidated: (value) => print("Error: $value"),
                  onInputChanged: (value) {
                    setState(() {
                      _phoneNumber = value.phoneNumber.toString();
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(
                onPressed: () {
                  print(_formKey.currentState?.validate());
                  if (_formKey.currentState?.validate() != null) {
                    if (_formKey.currentState!.validate()) {
                      if (_phoneNumber.length == 13) {
                        print("-----");
                        print(_phoneNumber);
                        registerUser(_phoneNumber, context);
                      }
                    }
                  }
                },
                child: const Text('Get OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
