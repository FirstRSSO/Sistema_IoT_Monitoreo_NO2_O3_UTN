import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterSensorMapper {
  final double no2;
  final double o3;
  final double temperatura;
  final int humedad;
  final int prediccion;
  final dynamic timestamp;
  final GeoPoint? ubicacion;

  RegisterSensorMapper({
    required this.no2,
    required this.o3,
    required this.temperatura,
    required this.humedad,
    required this.prediccion,
    required this.timestamp,
    this.ubicacion,
  });

  factory RegisterSensorMapper.fromMap(Map<String, dynamic> map) {
    return RegisterSensorMapper(
      no2: (map['no2'] ?? 0).toDouble(),
      o3: (map['o3'] ?? 0).toDouble(),
      temperatura: (map['temperatura'] ?? 0).toDouble(),
      humedad: (map['humedad'] ?? 0).toInt(),
      prediccion: map['prediccion'] ?? '',
      timestamp: map['timestamp'],
      ubicacion: map['ubicacion'],
    );
  }
}