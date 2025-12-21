import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapCircle extends StatelessWidget {
  const MapCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
          options: MapOptions(
            // center: LatLng(51.509364, -0.128928),
            center: LatLng(0.3317561653466711, -78.11804322598923),
            zoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_toner_background/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(0.3317561653466711, -78.11804322598923),
                  width: 80,
                  height: 80,
                  builder: (context) => const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
                Marker(
                  point: LatLng(0.3334997708348289, -78.1180718128431),
                  width: 80,
                  height: 80,
                  builder: (context) => const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(0.3317561653466711,
                      -78.11804322598923), // center of 't Gooi
                  radius: 100,
                  useRadiusInMeter: true,
                  color: Colors.red.withOpacity(0.3),
                  borderColor: Colors.red.withOpacity(0.7),
                  borderStrokeWidth: 2,
                )
              ],
            ),
            
          ],
        );
  }
}