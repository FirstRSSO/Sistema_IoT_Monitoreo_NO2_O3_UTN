import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';
import 'package:flutter_web_aiq/config/services/navigation_service.dart';
import 'package:flutter_web_aiq/infrastructure/datasources/register_sensor_datasource.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:flutter_web_aiq/locator.dart';
import 'package:flutter_web_aiq/presentation/providers/map_provider.dart';
import 'package:flutter_web_aiq/presentation/providers/table_map_provider.dart';
import 'package:flutter_web_aiq/presentation/shared/table_main.dart';
import 'package:flutter_web_aiq/presentation/shared/widgets/label_text_day.dart';
import 'package:flutter_web_aiq/presentation/views/map_view.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  final DateTime? fecha;
  final LatLng? locations;
  const MapPage({super.key, this.fecha, this.locations});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final RegisterSensorDatasource datasource = RegisterSensorDatasource();
  late Future<List<RegisterSensorMapper>> _futureRegistros;
  
  DateTimeRange? selectedDateRange;
  bool _animationScheduled = false; // 👈 asegurar que se ejecute una sola vez

  @override
  void initState() {
    super.initState();
    if (widget.fecha != null) {
      selectedDateRange = DateTimeRange(start: widget.fecha!, end: widget.fecha!);
      _futureRegistros = datasource.getRegistrosPorFecha(widget.fecha!);
      // print("Prueba: ${widget.fecha}");
    } else {
      selectedDateRange = null;
      _futureRegistros = datasource.getRegistrosUltimoDiaRegistrado();
    }

    TableMapProvider.initAnimations(this);
  }

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
        // Cargar registros del rango de fechas seleccionado
        _futureRegistros = datasource.getRegistrosPorRangoFechas(
            pickedDateRange.start, pickedDateRange.end);
      });
    }
  }

  @override
  // void dispose() {

  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // 👈 Proveer el MapProvider arriba del FutureBuilder
      create: (_) => MapProvider(),
      child: FutureBuilder<List<RegisterSensorMapper>>(
        future: _futureRegistros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // return const Center(child: Text('No hay datos aún'));
            final l10n = AppLocalizations.of(context)!;
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(Icons.info_outline,
                          size: 48, color: Colors.blueGrey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('no_data_selected_date'),
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
                          l10n.translate('reload_map'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDateRange = null;
                            _futureRegistros =
                                datasource.getRegistrosUltimoDiaRegistrado();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final registro = snapshot.data!;

          // 👇 Programar la animación solo cuando ya hay datos y MapView se construye
          if (!_animationScheduled && widget.locations != null) {
            _animationScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<MapProvider>().animateToLocation(
                widget.locations!,
                zoom: 16.0,
              );
            });
          }

          return Stack(
            children: [
              MapView(registros: registro),
              // if (widget.locations != null) {
              //   MapAnimator(
              //     locations: widget.locations,
              //   )
              // },
              AnimatedBuilder(
                animation: TableMapProvider.menuController,
                builder: (context, _) => Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(
                        TableMapProvider.movement.value,
                        0,
                      ),
                      child: SizedBox(
                        width: 850,
                        height: 400,
                        child: Stack(
                          children: [
                            TableMain(registros: registro),
                            _buildRegister()
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                top: 5,
                left: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    child: IconButton(
                        onPressed: () {
                          TableMapProvider.toggleMenu();
                          // print(registro.length);
                        },
                        icon: const Icon(Icons.menu_outlined)),
                  ),
                ),
              ),
              
              Positioned(
              top: 5,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: Colors.white,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateLabel(registro),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.calendar_month_outlined),
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
                ),
              ),
            ),
              _barBottomState()
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateLabel(List<RegisterSensorMapper> registros) {
    if (selectedDateRange == null) {
      // Si no hay rango, muestra la fecha del primer registro (último día)
      if (registros.isNotEmpty) {
        return LabelTextDay(registro: registros.first);
      }
      final l10n = AppLocalizations.of(context)!;
      return Text(l10n.translate('loading')); // O un widget de carga
    }

    final start = DateFormat('dd/MM/yy').format(selectedDateRange!.start);
    final end = DateFormat('dd/MM/yy').format(selectedDateRange!.end);

    if (start == end) {
      return Text(start);
    }

    return Text('$start - $end');
  }

  Align _barBottomState() {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 500,
        height: 30,
        child: Row(
          children: [
            _buildAQISegment(Colors.green, l10n.translate('good')),
            _buildAQISegment(Colors.yellow, l10n.translate('moderate')),
            _buildAQISegment(Colors.red, l10n.translate('unhealthy')),
          ],
        ),
      ),
    );
  }

  Widget _buildAQISegment(Color color, String label) {
    return Expanded(
      child: Container(
        color: color,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }

  Positioned _buildRegister() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 195,
      left: 2,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 180,
            height: 25,
            color: Colors.white.withOpacity(0.8),
            child: Center(
                child: Row(
              children: [
                const Icon(Icons.zoom_in),
                TextButton(
                  onPressed: () {
                    locator<NavigationService>().navigateTo('/history');
                  },
                  child: Text(
                    l10n.translate('view_history'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ),
      ),
    );
  }
}
