import 'package:flutter/material.dart';

class CustomFlatButton extends StatelessWidget {
  final String text;
  final Color color;
  final Function onPressed;

  const CustomFlatButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.pink,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(foregroundColor: color),
        onPressed: () {
          onPressed();
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(text),
        ));
  }
}