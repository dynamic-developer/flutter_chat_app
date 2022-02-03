import 'package:chat_app/Screens/AvailableGroupScreen/availablegroupscreen.dart';
import 'package:chat_app/Screens/ChatScreen/chatscreen.dart';
import 'package:chat_app/Screens/GroupChatScreen/groupchatscreen.dart';
import 'package:chat_app/Screens/HomeScreen/homescreen.dart';
import 'package:chat_app/Screens/LoginScreen/loginscreen.dart';
import 'package:chat_app/Screens/SettingScreen/settingscreen.dart';
import 'package:flutter/cupertino.dart';

final Map<String, WidgetBuilder> routes = {
  // LandingPage.routeName: (_) => LandingPage(),
  LoginScreen.routeName: (_) => LoginScreen(),
  HomeScreen.routeName: (_) => HomeScreen(),
  ChatScreen.routeName: (_) => const ChatScreen(),
  GroupChatScreen.routeName: (_) => const GroupChatScreen(),
  AvailableGroupScreen.routeName: (_) => AvailableGroupScreen(),
  SettingScreen.routeName: (_) => SettingScreen(),
};
