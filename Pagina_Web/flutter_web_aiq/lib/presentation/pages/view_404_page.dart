import 'package:flutter_web_aiq/presentation/shared/custom_flat_button.dart';
import 'package:flutter/material.dart';

class View404Page extends StatelessWidget {
  const View404Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('404', style:  TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
            SizedBox(height: 10,),
            Text('No se encontró la página', style:  TextStyle(fontSize: 40),),
            CustomFlatButton(text: 'Regresar', onPressed: ()=> Navigator.pushNamed(context, '/stateful'))
          ],
        ),
      );
  }
}