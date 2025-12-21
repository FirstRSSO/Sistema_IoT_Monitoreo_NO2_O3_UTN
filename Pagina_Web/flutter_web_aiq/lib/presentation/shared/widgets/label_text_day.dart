import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:intl/intl.dart';

class LabelTextDay extends StatelessWidget {
  final RegisterSensorMapper registro;
  const LabelTextDay({super.key, required this.registro});
  @override
  Widget build(BuildContext context) {
    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(registro.timestamp * 1000);
    final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    return Text(formattedDate);
  }
}