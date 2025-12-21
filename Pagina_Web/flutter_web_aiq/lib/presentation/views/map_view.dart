import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_web_aiq/infrastructure/mappers/register_sensor_mapper.dart';
import 'package:flutter_web_aiq/presentation/providers/map_provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// Clase auxiliar para representar un grupo de registros
class Cluster {
  final LatLng location;
  final List<RegisterSensorMapper> registros;
  Cluster({required this.location, required this.registros});
}

class MapView extends StatefulWidget {
  final List<RegisterSensorMapper> registros;

  MapView({super.key, required this.registros});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  late final MapController _mapController;
  final PopupController _popupController = PopupController();
  MapProvider? _mapProvider; // 👈 Nullable y manejado con cuidado

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener el provider actual y gestionar el listener
    final newProvider = Provider.of<MapProvider>(context, listen: false);
    if (_mapProvider != newProvider) {
      _mapProvider?.removeListener(_handleMapAnimation);
      _mapProvider = newProvider;
      _mapProvider!.addListener(_handleMapAnimation);

      // Si hay una animación pendiente al momento de suscribirse, ejecutarla
      if (_mapProvider!.shouldAnimate &&
          _mapProvider!.targetLocation != null &&
          _mapProvider!.targetZoom != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMapAnimation();
        });
      }
    }
  }

  @override
  void dispose() {
    _mapProvider?.removeListener(_handleMapAnimation);
    super.dispose();
  }

  void _handleMapAnimation() {
    if (_mapProvider == null) return;
    if (_mapProvider!.shouldAnimate &&
        _mapProvider!.targetLocation != null &&
        _mapProvider!.targetZoom != null) {
      _animatedMapMove(_mapProvider!.targetLocation!, _mapProvider!.targetZoom!);
      _mapProvider!.resetAnimation();
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.registros.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 👉 Agrupar registros antes de construir los marcadores
    final List<Cluster> clusters = _clusterRegistros(widget.registros, 50); // 50 metros de radio

    if (clusters.isEmpty) {
      return const Center(child: Text("No hay registros con ubicación para mostrar."));
    }

    final List<Marker> _markers = clusters.map((cluster) {
      return _markerFromCluster(cluster);
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(
          _markers.first.point.latitude,
          _markers.first.point.longitude,
        ),
        zoom: 13,
        onTap: (_, __) => _popupController.hideAllPopups(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        CircleLayer(
          circles: clusters.map((cluster) {
            // Calcular predicción promedio para el color del círculo
            final avgPrediction = (cluster.registros.map((r) => r.prediccion).reduce((a, b) => a + b) / cluster.registros.length).round();

            Color color;
            switch (avgPrediction) {
              case 0:
                color = Colors.green.withOpacity(0.2);
                break;
              case 1:
                color = Colors.yellow.withOpacity(0.2);
                break;
              case 2:
                color = Colors.red.withOpacity(0.2);
                break;
              default:
                color = Colors.grey.withOpacity(0.2);
            }

            return CircleMarker(
              point: cluster.location,
              radius: 30,
              color: color,
              borderStrokeWidth: 2,
              borderColor: color.withOpacity(0.8),
            );
          }).toList(),
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: _markers,
            popupController: _popupController,
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                final cluster = (marker.key as ValueKey).value as Cluster;
                return _buildPopup(cluster);
              },
            ),
          ),
        ),
      ],
    );
  }

  // 👉 Nueva función para agrupar registros
  List<Cluster> _clusterRegistros(List<RegisterSensorMapper> registros, double radiusInMeters) {
    final List<Cluster> clusters = [];
    final List<RegisterSensorMapper> remaining = List.from(registros.where((r) => r.ubicacion != null));
    const Distance distance = Distance();

    while (remaining.isNotEmpty) {
      final base = remaining.first;
      final clusterRegistros = <RegisterSensorMapper>[];
      
      // Usamos un iterador para poder eliminar elementos de forma segura
      final iterator = remaining.iterator;
      while(iterator.moveNext()) {
        final current = iterator.current;
        // Convertir GeoPoint a LatLng antes de calcular la distancia
        final baseLatLng = LatLng(base.ubicacion!.latitude, base.ubicacion!.longitude);
        final currentLatLng = LatLng(current.ubicacion!.latitude, current.ubicacion!.longitude);
        final d = distance(baseLatLng, currentLatLng);
        if (d <= radiusInMeters) {
          clusterRegistros.add(current);
        }
      }

      // Eliminar los registros ya agrupados de la lista de pendientes
      for (var reg in clusterRegistros) {
        remaining.remove(reg);
      }

      // Usar LatLng como ubicación del cluster
      final baseLatLng = LatLng(base.ubicacion!.latitude, base.ubicacion!.longitude);
      clusters.add(Cluster(location: baseLatLng, registros: clusterRegistros));
    }
    return clusters;
  }

  /// Crea un Marker desde un Cluster
  Marker _markerFromCluster(Cluster cluster) {
    final avgPrediction = (cluster.registros.map((r) => r.prediccion).reduce((a, b) => a + b) / cluster.registros.length).round();
    
    Color color;
    switch (avgPrediction) {
      case 0:
        color = Colors.green;
        break;
      case 1:
        color = const Color.fromARGB(255, 238, 216, 23);
        break;
      case 2:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Marker(
      key: ValueKey(cluster), // 👈 guardamos el cluster aquí
      point: cluster.location,
      width: 30,
      height: 40,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_on, color: color, size: 40),
          if (cluster.registros.length > 1)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  cluster.registros.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Popup personalizado con datos promediados del cluster
  Widget _buildPopup(Cluster cluster) {
    final count = cluster.registros.length;
    final isGroup = count > 1;

    // Calcular promedios
    final avgNo2 = cluster.registros.map((r) => r.no2).reduce((a, b) => a + b) / count;
    final avgO3 = cluster.registros.map((r) => r.o3).reduce((a, b) => a + b) / count;
    final avgTemp = cluster.registros.map((r) => r.temperatura).reduce((a, b) => a + b) / count;
    final avgHumedad = cluster.registros.map((r) => r.humedad).reduce((a, b) => a + b) / count;
    final avgPrediction = (cluster.registros.map((r) => r.prediccion).reduce((a, b) => a + b) / count).round();
    final lastTimestamp = cluster.registros.map((r) => r.timestamp).reduce((a, b) => a > b ? a : b);

    String predictionText;
    switch (avgPrediction) {
      case 0: predictionText = "Bueno"; break;
      case 1: predictionText = "Moderado"; break;
      case 2: predictionText = "Insalubre"; break;
      default: predictionText = "Desconocido";
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGroup)
              Text("📍 Grupo de $count registros cercanos", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!isGroup)
              Text("📍 Ubicación: ${cluster.location.latitude.toStringAsFixed(5)}, ${cluster.location.longitude.toStringAsFixed(5)}"),
            const SizedBox(height: 4),
            Text("💨 NO2: ${avgNo2.toStringAsFixed(2)} ${isGroup ? '(promedio)' : ''}"),
            Text("☁️ O3: ${avgO3.toStringAsFixed(2)} ${isGroup ? '(promedio)' : ''}"),
            Text("🌡️ Temp: ${avgTemp.toStringAsFixed(1)} °C ${isGroup ? '(promedio)' : ''}"),
            Text("💧 Humedad: ${avgHumedad.toStringAsFixed(1)} % ${isGroup ? '(promedio)' : ''}"),
            Text("Predicción: $predictionText ${isGroup ? '(promedio)' : ''}"),
            const SizedBox(height: 4),
            Text("Última actualización:"),
            Text("  Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(lastTimestamp * 1000))}"),
            Text("  Hora: ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(lastTimestamp * 1000))}"),
          ],
        ),
      ),
    );
  }
}
