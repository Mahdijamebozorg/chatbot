import 'package:flutter/animation.dart';

class Message {
  String text;
  final bool isUser;
  List<String> buttons;
  final AnimationController animation;

  Message({
    required this.text,
    required this.isUser,
    required this.animation,
    this.buttons = const [],
  });
}
