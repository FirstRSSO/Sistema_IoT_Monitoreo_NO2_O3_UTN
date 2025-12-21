import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';

class RegisterSensorDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los registros
  Future<List<RegisterSensorMapper>> getRegistros() async {
    final snapshot = await _firestore
        .collection('registros')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return RegisterSensorMapper.fromMap(data);
    }).toList();
  }

  // Obtener los últimos N registros
  Future<List<RegisterSensorMapper>> getUltimosRegistros(int limite) async {
    final snapshot = await _firestore
        .collection('registros')
        .orderBy('timestamp', descending: true)
        .limit(limite)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return RegisterSensorMapper.fromMap(data);
    }).toList();
  }

// 👉 Obtener registros de un día específico
Future<List<RegisterSensorMapper>> getRegistrosPorFecha(DateTime fecha) async {
  final inicio = DateTime(fecha.year, fecha.month, fecha.day);
  final fin = inicio.add(const Duration(days: 1));

  // convertir a UNIX segundos
  final inicioSegundos = inicio.millisecondsSinceEpoch ~/ 1000;
  final finSegundos = fin.millisecondsSinceEpoch ~/ 1000;

  // print('Buscando registros desde: $inicioSegundos hasta: $finSegundos');

  final snapshot = await _firestore
      .collection('registros')
      .where('timestamp', isGreaterThanOrEqualTo: inicioSegundos)
      .where('timestamp', isLessThan: finSegundos)
      .orderBy('timestamp', descending: true)
      .get();

  // print('Registros encontrados: ${snapshot.docs.length}');

  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegisterSensorMapper.fromMap(data);
  }).toList();
}

// 👉 Obtener registros de un rango de fechas
Future<List<RegisterSensorMapper>> getRegistrosPorRangoFechas(DateTime inicio, DateTime fin) async {
  // Aseguramos que el rango incluya todo el día final
  final finDelDia = DateTime(fin.year, fin.month, fin.day, 23, 59, 59);

  final inicioSegundos = inicio.millisecondsSinceEpoch ~/ 1000;
  final finSegundos = finDelDia.millisecondsSinceEpoch ~/ 1000;

  final snapshot = await _firestore
      .collection('registros')
      .where('timestamp', isGreaterThanOrEqualTo: inicioSegundos)
      .where('timestamp', isLessThanOrEqualTo: finSegundos)
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegisterSensorMapper.fromMap(data);
  }).toList();
}

  // 👉 Obtener registros del último día disponible en la BD
  Future<List<RegisterSensorMapper>> getRegistrosUltimoDiaRegistrado() async {
    // 1. Obtener el último registro
    final ultimoSnapshot = await _firestore
        .collection('registros')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (ultimoSnapshot.docs.isEmpty) return [];

    final ultimoData = ultimoSnapshot.docs.first.data() as Map<String, dynamic>;
    final ultimo = RegisterSensorMapper.fromMap(ultimoData);

    // 2. Calcular inicio y fin de ese día
    final fechaUltimo = DateTime.fromMillisecondsSinceEpoch(ultimo.timestamp * 1000);
    final inicio = DateTime(fechaUltimo.year, fechaUltimo.month, fechaUltimo.day);
    final fin = inicio.add(const Duration(days: 1));

    // 3. Consultar todos los registros de ese día
    final snapshot = await _firestore
        .collection('registros')
        .where('timestamp',
            isGreaterThanOrEqualTo: inicio.millisecondsSinceEpoch ~/ 1000)
        .where('timestamp',
            isLessThan: fin.millisecondsSinceEpoch ~/ 1000)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return RegisterSensorMapper.fromMap(data);
    }).toList();
  }
}
