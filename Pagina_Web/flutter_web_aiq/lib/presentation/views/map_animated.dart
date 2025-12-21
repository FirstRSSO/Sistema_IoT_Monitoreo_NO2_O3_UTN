import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnimatedMapExample extends StatefulWidget {
  const AnimatedMapExample({Key? key}) : super(key: key);

  @override
  State<AnimatedMapExample> createState() => _AnimatedMapExampleState();
}

class _AnimatedMapExampleState extends State<AnimatedMapExample>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  static final london = LatLng(51.5, -0.09);
  static final paris = LatLng(48.8566, 2.3522);
  static final dublin = LatLng(53.3498, -6.2603);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.zoom, end: destZoom);

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
    final markers = <Marker>[
      Marker(
        point: london,
        width: 50,
        height: 50,
        builder: (_) =>
            const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
      Marker(
        point: paris,
        width: 50,
        height: 50,
        builder: (_) =>
            const Icon(Icons.location_on, color: Colors.blue, size: 40),
      ),
      Marker(
        point: dublin,
        width: 50,
        height: 50,
        builder: (_) =>
            const Icon(Icons.location_on, color: Colors.green, size: 40),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Animated Map Example")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _animatedMapMove(london, 10),
                child: const Text("London"),
              ),
              ElevatedButton(
                onPressed: () => _animatedMapMove(paris, 5),
                child: const Text("Paris"),
              ),
              ElevatedButton(
                onPressed: () => _animatedMapMove(dublin, 7),
                child: const Text("Dublin"),
              ),
            ],
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: london,
                zoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
