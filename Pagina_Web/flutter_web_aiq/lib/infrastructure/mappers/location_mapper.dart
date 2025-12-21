import 'dart:convert';

LocationMapper locationMapperFromJson(String str) => LocationMapper.fromJson(json.decode(str));

class LocationMapper {
    double latitude;
    String lookupSource;
    double longitude;
    String localityLanguageRequested;
    String continent;
    String continentCode;
    String countryName;
    String countryCode;
    String principalSubdivision;
    String principalSubdivisionCode;
    String city;
    String locality;
    String postcode;
    String plusCode;
    LocalityInfo localityInfo;

    LocationMapper({
        required this.latitude,
        required this.lookupSource,
        required this.longitude,
        required this.localityLanguageRequested,
        required this.continent,
        required this.continentCode,
        required this.countryName,
        required this.countryCode,
        required this.principalSubdivision,
        required this.principalSubdivisionCode,
        required this.city,
        required this.locality,
        required this.postcode,
        required this.plusCode,
        required this.localityInfo,
    });

    factory LocationMapper.fromJson(Map<String, dynamic> json) => LocationMapper(
        latitude: json["latitude"]?.toDouble() ?? 0.0,
        lookupSource: json["lookupSource"] ?? '',
        longitude: json["longitude"]?.toDouble() ?? 0.0,
        localityLanguageRequested: json["localityLanguageRequested"] ?? '',
        continent: json["continent"] ?? '',
        continentCode: json["continentCode"] ?? '',
        countryName: json["countryName"] ?? '',
        countryCode: json["countryCode"] ?? '',
        principalSubdivision: json["principalSubdivision"] ?? '',
        principalSubdivisionCode: json["principalSubdivisionCode"] ?? '',
        city: json["city"] ?? '',
        locality: json["locality"] ?? '',
        postcode: json["postcode"] ?? '',
        plusCode: json["plusCode"] ?? '',
        localityInfo: LocalityInfo.fromJson(json["localityInfo"] ?? {}),
    );
}

class LocalityInfo {
    List<Ative> administrative;
    List<Ative> informative;

    LocalityInfo({
        required this.administrative,
        required this.informative,
    });

    factory LocalityInfo.fromJson(Map<String, dynamic> json) => LocalityInfo(
        administrative: json["administrative"] != null ? List<Ative>.from(json["administrative"].map((x) => Ative.fromJson(x))) : [],
        informative: json["informative"] != null ? List<Ative>.from(json["informative"].map((x) => Ative.fromJson(x))) : [],
    );
}

class Ative {
    String name;
    String description;
    String? isoName;
    int order;
    int? adminLevel;
    String? isoCode;
    String? wikidataId;
    int? geonameId;

    Ative({
        required this.name,
        required this.description,
        this.isoName,
        required this.order,
        this.adminLevel,
        this.isoCode,
        this.wikidataId,
        this.geonameId,
    });

    factory Ative.fromJson(Map<String, dynamic> json) => Ative(
        name: json["name"] ?? '',
        description: json["description"] ?? '',
        isoName: json["isoName"],
        order: json["order"] ?? 0,
        adminLevel: json["adminLevel"],
        isoCode: json["isoCode"],
        wikidataId: json["wikidataId"],
        geonameId: json["geonameId"],
    );
}
