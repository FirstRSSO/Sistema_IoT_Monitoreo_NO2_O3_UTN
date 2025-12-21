import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/infrastructure/datasources/register_sensor_datasource.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:intl/intl.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final RegisterSensorDatasource datasource = RegisterSensorDatasource();

  late Future<List<RegisterSensorMapper>> _futureRegistros;

  @override
  void initState() {
    super.initState();
    // _futureRegistros = datasource.getRegistros();
    _futureRegistros = datasource.getUltimosRegistros(4);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: Text('Registros Firestore')),
      body: FutureBuilder<List<RegisterSensorMapper>>(
        future: _futureRegistros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {

            return const Center(child: Text('No hay datos aún'));
          }

          final registros = snapshot.data!;
          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final r = registros[index];
              // final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(r.timestamp * 1000); // Asumiendo que r.timestamp está en segundos
              // final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime); 
              final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(r.timestamp * 1000);
              final String soloHora = DateFormat('HH:mm').format(dateTime);
              final String soloFecha = DateFormat('dd/MM/yyyy').format(dateTime);
              final String soloFechaTexto = DateFormat('MMMM d, yyyy').format(dateTime);
              
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text('Predicción: ${r.prediccion}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NO₂: ${r.no2} ppm'),
                      Text('O₃: ${r.o3} ppm'),
                      Text('Temperatura: ${r.temperatura} °C'),
                      Text('Humedad: ${r.humedad} %'),
                      Text(
                        'Ubicación: ${r.ubicacion != null 
                          ? 'Lat: ${r.ubicacion!.latitude.toStringAsFixed(4)}, Lng: ${r.ubicacion!.longitude.toStringAsFixed(4)}' 
                          : 'No disponible'}',
                      ),
                      // Text('Fecha y hora: $formattedDate'),
                      Text('Fecha: $soloFecha'),
                      Text('Fecha en texto: $soloFechaTexto'),
                      Text('Hora: $soloHora'),
                      
                      
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}