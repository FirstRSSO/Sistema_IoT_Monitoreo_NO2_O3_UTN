import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';
import 'package:flutter_web_aiq/config/services/navigation_service.dart';
import 'package:flutter_web_aiq/infrastructure/datasources/location_datasource.dart';
import 'package:flutter_web_aiq/infrastructure/datasources/register_sensor_datasource.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/location_mapper.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:flutter_web_aiq/locator.dart';
import 'package:flutter_web_aiq/presentation/providers/map_provider.dart';
import 'package:flutter_web_aiq/presentation/shared/widgets/tendencia_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum Dispositivos { ibarra01, ibarra02 }

class _HistoryPageState extends State<HistoryPage> {
  final RegisterSensorDatasource datasource = RegisterSensorDatasource();
  final LocationDatasource _locationDatasource = LocationDatasource();
  final Map<String, Future<LocationMapper>> _locationCache = {};

  late Future<List<RegisterSensorMapper>> _futureRegistros;
  final ScrollController _verticalController = ScrollController();
  Dispositivos selectedDispositivo = Dispositivos.ibarra01;

  DateTimeRange? selectedDateRange;

  Future<void> _selectSingleDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateRange?.start ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDateRange = DateTimeRange(start: pickedDate, end: pickedDate);
        _locationCache.clear();
        _futureRegistros = datasource.getRegistrosPorFecha(pickedDate);
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (pickedDateRange != null && pickedDateRange != selectedDateRange) {
      setState(() {
        selectedDateRange = pickedDateRange;
        _locationCache.clear();
        _futureRegistros = datasource.getRegistrosPorRangoFechas(
            pickedDateRange.start, pickedDateRange.end);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _futureRegistros = datasource.getRegistrosUltimoDiaRegistrado();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  Future<LocationMapper> _getLocation(double lat, double lon) {
    final key = '$lat,$lon';
    if (!_locationCache.containsKey(key)) {
      _locationCache[key] = _locationDatasource.getLocationInfo(lat, lon);
    }
    return _locationCache[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FutureBuilder<List<RegisterSensorMapper>>(
        future: _futureRegistros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.blueGrey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('no_data_for_date'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      l10n.translate('load_last_day'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedDateRange = null;
                        _futureRegistros = datasource.getRegistrosUltimoDiaRegistrado();
                      });
                    },
                  ),
                ],
              ),
            );
          }
          final registro = snapshot.data!;

          // --- CÁLCULOS PARA EL RESUMEN ---
          // Promedio de NO2 y O3
          final double promedioNO2 = registro.map((m) => m.no2).reduce((a, b) => a + b) / registro.length;
          final double promedioO3 = registro.map((m) => m.o3).reduce((a, b) => a + b) / registro.length;

          // Moda para la Calidad del Aire
          final counts = <int, int>{};
          for (final m in registro) {
            counts[m.prediccion] = (counts[m.prediccion] ?? 0) + 1;
          }
          int modaPrediccion = -1;
          int maxCount = 0;
          counts.forEach((key, value) {
            if (value > maxCount) {
              maxCount = value;
              modaPrediccion = key;
            }
          });
          final l10n = AppLocalizations.of(context)!;
          String modaCalidadAire;
          switch (modaPrediccion) {
            case 0:
              modaCalidadAire = l10n.translate('good');
              break;
            case 1:
              modaCalidadAire = l10n.translate('moderate');
              break;
            case 2:
              modaCalidadAire = l10n.translate('unhealthy_for_sensitive');
              break;
            default:
              modaCalidadAire = l10n.translate('not_available');
          }
          // --- FIN DE CÁLCULOS ---

          // --- CÁLCULOS PARA GRÁFICOS DE TENDENCIA ---
          List<FlSpot> no2Spots = [];
          List<FlSpot> o3Spots = [];
          double no2Percentage = 0.0;
          double o3Percentage = 0.0;
          String ultimoValorNO2 = 'N/A';
          String ultimoValorO3 = 'N/A';

          if (registro.isNotEmpty) {
            // Asegurarse de que los registros estén ordenados por tiempo
            registro.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            no2Spots = registro.map((m) {
              final time = DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000);
              final timeAsDouble = time.hour + (time.minute / 60.0);
              return FlSpot(timeAsDouble, m.no2.toDouble());
            }).toList();

            o3Spots = registro.map((m) {
              final time = DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000);
              final timeAsDouble = time.hour + (time.minute / 60.0);
              return FlSpot(timeAsDouble, m.o3.toDouble());
            }).toList();

            ultimoValorNO2 = '${registro.last.no2} ppm';
            ultimoValorO3 = '${registro.last.o3} ppb';

            if (registro.length > 1) {
              final firstNo2 = registro.first.no2;
              if (firstNo2 > 0) {
                no2Percentage = ((registro.last.no2 - firstNo2) / firstNo2) * 100;
              }

              final firstO3 = registro.first.o3;
              if (firstO3 > 0) {
                o3Percentage = ((registro.last.o3 - firstO3) / firstO3) * 100;
              }
            }
          }
          // --- FIN DE CÁLCULOS DE TENDENCIA ---

          return SizedBox(
            width: size.width,
            height: double.infinity,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16), // Mejor padding
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('measurements'),
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 24),
                        _buildPopupMenu(),
                        const Spacer(),
                        _buildDateLabel(),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.calendar_month_outlined, color: Colors.blueAccent),
                          tooltip: 'Seleccionar fecha',
                          onSelected: (value) {
                            if (value == 'day') {
                              _selectSingleDate();
                            } else if (value == 'range') {
                              _selectDateRange();
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            final l10n = AppLocalizations.of(context)!;
                            return <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'day',
                                child: Text(l10n.translate('select_day')),
                              ),
                              PopupMenuItem<String>(
                                value: 'range',
                                child: Text(l10n.translate('select_range')),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Scroll vertical + horizontal
                    _buildTable(registro),
                    SizedBox(width: size.width, height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Text(
                        l10n.translate('measurement_summary'),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: size.width, height: 10),
                    SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Row(
                          children: [
                            SizedBox(
                              width: size.width * 0.325,
                              height: 100,
                              child: Card(
                                  borderOnForeground: true,
                                  elevation: 5.0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.translate('average_no2'),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        Text(
                                          '${promedioNO2.toStringAsFixed(1)} ppm',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                            SizedBox(
                              width: size.width * 0.325,
                              height: 100,
                              child: Card(
                                  borderOnForeground: true,
                                  elevation: 5.0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.translate('average_o3'),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        Text(
                                          '${promedioO3.toStringAsFixed(1)} ppb',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                            SizedBox(
                              width: size.width * 0.325,
                              height: 100,
                              child: Card(
                                  borderOnForeground: true,
                                  elevation: 5.0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.translate('air_quality'),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        Text(
                                          modaCalidadAire,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                          ],
                        )),
                    SizedBox(
                      width: size.width,
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: Row(
                        children: [
                          TendenciaCard(
                            titulo: l10n.translate('no2_trend'),
                            valor: ultimoValorNO2,
                            porcentaje: no2Percentage,
                            puntos: no2Spots,
                          ),
                          const SizedBox(width: 16),
                          TendenciaCard(
                            titulo: l10n.translate('o3_trend'),
                            valor: ultimoValorO3,
                            porcentaje: o3Percentage,
                            puntos: o3Spots,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildDateLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (selectedDateRange == null) {
      return Text(
        l10n.translate('last_registered_day'),
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      );
    }

    final start = DateFormat('dd/MM/yyyy').format(selectedDateRange!.start);
    final end = DateFormat('dd/MM/yyyy').format(selectedDateRange!.end);

    if (start == end) {
      return Text(
        start,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      );
    }

    return Text(
      '$start - $end',
      style: const TextStyle(fontSize: 16, color: Colors.black54),
    );
  }

  Widget _buildTable(List<RegisterSensorMapper> registros) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity, // Fijo como en la imagen de referencia
      height: 400, // Puedes ajustar la altura según necesites
      child: Scrollbar(
        thumbVisibility: true,
        controller: _verticalController,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 100, // Ajustado para más columnas
                  columns: [
                    DataColumn(label: Text(l10n.translate('location'))),
                    DataColumn(label: Text(l10n.translate('date'))),
                    DataColumn(label: Text(l10n.translate('time'))),
                    DataColumn(label: Text(l10n.translate('temperature'))),
                    DataColumn(label: Text('NO2')),
                    DataColumn(label: Text('O3')),
                    DataColumn(label: Text(l10n.translate('air_quality'))),
                  ],
                  rows: registros.map((m) {
                    return DataRow(cells: [
                      DataCell(
                        FutureBuilder<LocationMapper>(
                          future: _getLocation(m.ubicacion!.latitude, m.ubicacion!.longitude),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text(l10n.translate('loading'));
                            }
                            
                            String displayText;
                            if (snapshot.hasError) {
                              displayText = '${l10n.translate('location_error')}\n(${m.ubicacion!.latitude}, ${m.ubicacion!.longitude})';
                            } else if (snapshot.hasData) {
                              final location = snapshot.data!;
                              displayText = '${location.locality}, ${location.principalSubdivision}\n(${m.ubicacion!.latitude}, ${m.ubicacion!.longitude})';
                            } else {
                              displayText = l10n.translate('location_unavailable');
                            }

                            return InkWell(
                              onTap: () {
                                // Suponiendo que usas go_router o similar
                                final dateTime = DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000);
                                final day = dateTime.day;
                                final month = dateTime.month;
                                final year = dateTime.year;
                                final lat = m.ubicacion!.latitude;
                                final lng = m.ubicacion!.longitude;

                                final url = '/map/marker/$day/$month/$year/$lat/$lng';

                                locator<NavigationService>().navigateTo(url);

                                // Future.delayed(Duration(milliseconds:10000), () {
                                //   final mapProvider = Provider.of<MapProvider>(context, listen: false);
                                //   mapProvider.animateToLocation(
                                //     LatLng(m.ubicacion!.latitude, m.ubicacion!.longitude),
                                //     zoom: 16.0,
                                //   );
                                // });
                                // context.push(url); // Descomenta esto cuando implementes la navegación
                              },
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000)))),
                      DataCell(Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000)))),
                      DataCell(Text('${m.temperatura.toStringAsFixed(1)} °C')),
                      DataCell(Text('${m.no2} ppm')),
                      DataCell(Text('${m.o3} ppb')),
                      DataCell(_buildCalidadChip(m.prediccion == 0
                          ? l10n.translate('good')
                          : m.prediccion == 1
                              ? l10n.translate('moderate')
                              : l10n.translate('unhealthy_for_sensitive'))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _buildPopupMenu() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupMenuButton<Dispositivos>(
            child: ListTile(
              title: Text("$selectedDispositivo"),
              subtitle: Text(selectedDispositivo == Dispositivos.ibarra01
                  ? l10n.translate('active_status')
                  : l10n.translate('inactive_status')),
              trailing: const Icon(Icons.arrow_drop_down),
            ),
            onSelected: (Dispositivos value) {
              setState(() {
                selectedDispositivo = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: Dispositivos.ibarra01,
                child: ListTile(
                  title: Text("$Dispositivos.ibarra01"),
                  subtitle: Text(l10n.translate('active_status')),
                  leading: Radio<Dispositivos>(
                    value: Dispositivos.ibarra01,
                    groupValue: selectedDispositivo,
                    onChanged: (value) {
                      setState(() {
                        selectedDispositivo = value!;
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
              ),
              PopupMenuItem(
                value: Dispositivos.ibarra02,
                child: ListTile(
                  title: Text("$Dispositivos.ibarra02"),
                  subtitle: Text(l10n.translate('inactive_status')),
                  leading: Radio<Dispositivos>(
                    value: Dispositivos.ibarra02,
                    groupValue: selectedDispositivo,
                    onChanged: (value) {
                      setState(() {
                        selectedDispositivo = value!;
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalidadChip(String calidad) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    // Comparar con traducciones para determinar color
    if (calidad == l10n.translate('good')) {
      color = Colors.green.shade200;
    } else if (calidad == l10n.translate('moderate')) {
      color = Colors.yellow.shade200;
    } else if (calidad == l10n.translate('unhealthy_for_sensitive')) {
      color = Colors.red.shade200;
    } else {
      color = Colors.grey.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        calidad,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class Medicion {
  final String ubicacion;
  final String fecha;
  final String hora;
  final int no2;
  final int o3;
  final String calidad;

  Medicion(
      this.ubicacion, this.fecha, this.hora, this.no2, this.o3, this.calidad);
}

final List<Medicion> mediciones = [
  Medicion(
      "Parque Central, Nueva York", "2024-03-15", "10:00 AM", 25, 30, "Buena"),
  Medicion("Plaza de los Tiempos, Nueva York", "2024-03-15", "11:00 AM", 40, 20,
      "Moderada"),
  Medicion("Puente de Brooklyn, Nueva York", "2024-03-15", "12:00 PM", 35, 25,
      "Moderada"),
  Medicion("Edificio del Estado Imperial, Nueva York", "2024-03-15", "1:00 PM",
      30, 35, "Buena"),
  Medicion("Estatua de la Libertad, Nueva York", "2024-03-15", "2:00 PM", 20,
      40, "Buena"),
  Medicion("Calle del Muro, Nueva York", "2024-03-15", "3:00 PM", 45, 15,
      "Poco Saludable"),
  Medicion("Terminal Central Grand, Nueva York", "2024-03-15", "4:00 PM", 38,
      28, "Moderada"),
  Medicion("Museo Metropolitano de Arte, Nueva York", "2024-03-15", "5:00 PM",
      28, 32, "Buena"),
  Medicion("Estadio de los Yankees, Nueva York", "2024-03-15", "6:00 PM", 32,
      22, "Moderada"),
  Medicion("Universidad de Columbia, Nueva York", "2024-03-15", "7:00 PM", 22,
      38, "Buena"),
];
