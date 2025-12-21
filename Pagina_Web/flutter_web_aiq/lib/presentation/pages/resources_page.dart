import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';
import 'package:flutter_web_aiq/infrastructure/datasources/register_sensor_datasource.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:intl/intl.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final RegisterSensorDatasource _datasource = RegisterSensorDatasource();
  List<RegisterSensorMapper>? _registros;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  Future<void> _selectSingleDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (pickedDate != null) {
      _loadData(DateTimeRange(start: pickedDate, end: pickedDate));
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (pickedDateRange != null) {
      _loadData(pickedDateRange);
    }
  }

  void _loadData(DateTimeRange dateRange) async {
    setState(() {
      _selectedDateRange = dateRange;
      _isLoading = true;
      _registros = null;
    });

    try {
      final List<RegisterSensorMapper> registros;
      if (dateRange.start == dateRange.end) {
        registros = await _datasource.getRegistrosPorFecha(dateRange.start);
      } else {
        registros = await _datasource.getRegistrosPorRangoFechas(
            dateRange.start, dateRange.end);
      }
      setState(() {
        _registros = registros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('error_loading_data')}: $e')),
      );
    }
  }

  Future<void> _exportToCsv() async {
    final l10n = AppLocalizations.of(context)!;
    if (_registros == null || _registros!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('no_data_to_export')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<List<dynamic>> rows = [];
    // Encabezados
    rows.add([
      'Timestamp',
      'Fecha',
      'Hora',
      'Latitud',
      'Longitud',
      'Temperatura',
      'NO2',
      'O3',
      'Prediccion_Calidad'
    ]);

    // Datos
    for (var registro in _registros!) {
      rows.add([
        registro.timestamp,
        DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(registro.timestamp * 1000)),
        DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(registro.timestamp * 1000)),
        registro.ubicacion?.latitude,
        registro.ubicacion?.longitude,
        registro.temperatura,
        registro.no2,
        registro.o3,
        registro.prediccion
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Crear y descargar el archivo
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
    final end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    final fileName = start == end ? 'registros_$start.csv' : 'registros_${start}_a_$end.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('download_started')),
          backgroundColor: Colors.green,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.download_for_offline_outlined, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                l10n.translate('export_records'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('select_date_load'),
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 16),
                          Text(
                            _buildDateLabel(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.edit_calendar),
                            tooltip: l10n.translate('select'),
                            onSelected: (value) {
                              if (value == 'day') {
                                _selectSingleDate();
                              } else if (value == 'range') {
                                _selectDateRange();
                              }
                            },
                            itemBuilder: (BuildContext buildContext) {
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
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_registros != null)
                        Text(
                          '${_registros!.length} ${l10n.translate('records_loaded')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _registros!.isEmpty ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download, size: 28),
                label: Text(l10n.translate('export_to_csv'), style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: (_registros != null && _registros!.isNotEmpty)
                      ? Colors.green
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_registros != null && _registros!.isNotEmpty) ? _exportToCsv : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDateLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDateRange == null) {
      return l10n.translate('no_date_selected');
    }
    final start = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start);
    final end = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end);
    if (start == end) {
      return '${l10n.translate('date_label')} $start';
    }
    return '${l10n.translate('range_label')} $start - $end';
  }
}