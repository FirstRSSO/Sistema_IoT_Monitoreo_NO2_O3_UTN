import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/presentation/shared/custom_app_menu.dart';

class MainLayoutPage extends StatelessWidget {
  final Widget child;
  const MainLayoutPage({super.key, required this.child});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            CustomAppMenu(),
            // Spacer(),
            Expanded(child: child),
            // Spacer(),
          ],
        ),
      ),
    );
  }
}
