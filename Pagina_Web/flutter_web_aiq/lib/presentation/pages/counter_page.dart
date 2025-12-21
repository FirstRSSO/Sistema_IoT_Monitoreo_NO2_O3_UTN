import 'package:flutter_web_aiq/presentation/shared/custom_flat_button.dart';
import 'package:flutter/material.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int counter = 10;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CusmtomAppMenu(),
        Spacer(),
        Text(
          'Contador Stateful',
          style: TextStyle(fontSize: 20),
        ),
        FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Contador: $counter',
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomFlatButton(
                text: 'Incremetar',
                onPressed: () {
                  setState(() {
                    counter++;
                  });
                }),
            CustomFlatButton(
                text: 'Decrementar',
                onPressed: () {
                  setState(() {
                    counter--;
                  });
                }),
          ],
        ),
        Spacer()
      ],
    );
  }
}
