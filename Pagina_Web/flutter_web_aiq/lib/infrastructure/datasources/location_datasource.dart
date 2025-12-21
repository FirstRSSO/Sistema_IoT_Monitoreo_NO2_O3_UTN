import 'dart:convert';
import 'package:flutter_web_aiq/infrastructure/mappers/location_mapper.dart';
import 'package:http/http.dart' as http;

class LocationDatasource {
  
  Future<LocationMapper> getLocationInfo(double latitude, double longitude) async {
    final url = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'localityLanguage': 'es',
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      return LocationMapper.fromJson(decodedData);
    } else {
      throw Exception('Failed to load location data');
    }
  }
}