import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:flutter_web_aiq/presentation/providers/map_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class TableMain extends StatefulWidget {
  final List<RegisterSensorMapper> registros;
  const TableMain({super.key, required this.registros});

  @override
  State<TableMain> createState() => _TableMainState();
}

class _TableMainState extends State<TableMain> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(0.90),
              3: FlexColumnWidth(0.80),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1.8),
              7: FlexColumnWidth(1.2),
            },
            children: [
              _buildHeaderRow(),
              ...widget.registros.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final r = entry.value;
                final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(r.timestamp * 1000);
                final String soloHora = DateFormat('HH:mm').format(dateTime);
                final String soloFecha = DateFormat('dd/MM/yyyy').format(dateTime);
                final l10n = AppLocalizations.of(context)!;
                return _buildDataRow([
                  soloFecha,
                  soloHora,
                  r.no2.toString(),
                  r.o3.toString(),
                  r.temperatura.toString(),
                  r.humedad.toString(),
                  if (r.prediccion == 0)
                        l10n.translate('good')
                      else if (r.prediccion == 1)
                        l10n.translate('moderate')
                      else if (r.prediccion == 2)
                        l10n.translate('unhealthy'),
                  (index + 1).toString(),
                ], r); // 👈 Pasamos también el registro
              }),
            ],
          )),
    );
  }

  TableRow _buildHeaderRow() {
    final l10n = AppLocalizations.of(context)!;
    final headers = [
      l10n.translate('date'),
      l10n.translate('time'),
      'NO2',
      'O3',
      l10n.translate('temperature'),
      l10n.translate('humidity'),
      l10n.translate('model_prediction'),
      l10n.translate('map_identifier'),
    ];

    return TableRow(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
      ),
      children: headers.map((text) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(List<String> values, RegisterSensorMapper registro) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
      ),
      children: values.asMap().entries.map((entry) {
        final colIndex = entry.key;
        final value = entry.value;

        // Si es la última columna (Identificador Mapa) → hacerlo pulsable
        if (colIndex == 7) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: () {
                // 👇 Usar el provider para animar el mapa
                if (registro.ubicacion != null) {
                  final mapProvider = Provider.of<MapProvider>(context, listen: false);
                  mapProvider.animateToLocation(
                    LatLng(registro.ubicacion!.latitude, registro.ubicacion!.longitude),
                    zoom: 16.0,
                  );
                  // print("Animando hacia: ${registro.ubicacion!.latitude}, ${registro.ubicacion!.longitude}");
                }
              },
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Para las demás columnas → normal
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}
