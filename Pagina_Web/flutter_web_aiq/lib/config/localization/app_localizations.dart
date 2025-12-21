import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Menú
      'map': 'Map',
      'measurements': 'Measurements',
      'resources': 'Resources',
      
      // Mapa
      'no_data': 'No data yet',
      'no_data_selected_date': 'No data collected on the selected date',
      'reload_map': 'Reload map with last record',
      'select_day': 'Select day',
      'select_range': 'Select range',
      'last_registered_day': 'Last registered day',
      'view_history': 'View history',
      
      // Calidad del aire
      'good': 'Good',
      'moderate': 'Moderate',
      'unhealthy': 'Unhealthy',
      'very_unhealthy': 'Very Unhealthy',
      'hazardous': 'Hazardous',
      'air_quality': 'Air Quality',
      
      // Mediciones
      'location': 'Location',
      'date': 'Date',
      'time': 'Time',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'model_prediction': 'Model Prediction',
      'map_identifier': 'Map Identifier',
      'loading': 'Loading...',
      'location_error': 'Location error',
      'location_unavailable': 'Location unavailable',
      
      // Resumen
      'measurement_summary': 'Measurement Summary',
      'average_no2': 'Average NO2',
      'average_o3': 'Average O3',
      'no2_trend': 'NO2 Trend',
      'o3_trend': 'O3 Trend',
      'today': 'Today',
      
      // Recursos
      'export_to_csv': 'Export to CSV',
      'export_records': 'Export Records to CSV',
      'select_date_load': 'Select a date or range to load records and then export them in CSV format.',
      'no_date_selected': 'No date selected',
      'records_loaded': 'records loaded and ready to export.',
      'no_data_to_export': 'No data to export. Please select a date and load the data.',
      'download_started': 'CSV file download has started.',
      'error_loading_data': 'Error loading data',
      
      // Popup
      'nearby_group': 'Group of',
      'nearby_records': 'nearby records',
      'prediction': 'Prediction',
      'average': 'average',
      'last_update': 'Last update',
      
      // Botones
      'select': 'Select',
      'load_last_day': 'Load last day with records',
      'cancel': 'Cancel',
      'accept': 'Accept',
      'close': 'Close',
      
      // Otros
      'historical_data': 'Historical Data',
      'real_time_data': 'Real-time Data',
      'statistics': 'Statistics',
      'no_records': 'No records found',
      'no_data_for_date': 'No data for the selected date',
      'unhealthy_for_sensitive': 'Unhealthy for Sensitive Groups',
      'not_available': 'Not available',
      'active_status': 'Active Status',
      'inactive_status': 'Inactive Status',
      'date_label': 'Date:',
      'range_label': 'Range:',
    },
    'es': {
      // Menú
      'map': 'Mapa',
      'measurements': 'Mediciones',
      'resources': 'Recursos',
      
      // Mapa
      'no_data': 'No hay datos aún',
      'no_data_selected_date': 'No hay datos recolectados en la fecha seleccionada',
      'reload_map': 'Recargar mapa con último registro',
      'select_day': 'Seleccionar día',
      'select_range': 'Seleccionar por rango',
      'last_registered_day': 'Último día registrado',
      'view_history': 'Ver registro histórico',
      
      // Calidad del aire
      'good': 'Bueno',
      'moderate': 'Moderado',
      'unhealthy': 'Insalubre',
      'very_unhealthy': 'Muy Insalubre',
      'hazardous': 'Peligroso',
      'air_quality': 'Calidad del Aire',
      
      // Mediciones
      'location': 'Ubicación',
      'date': 'Fecha',
      'time': 'Hora',
      'temperature': 'Temperatura',
      'humidity': 'Humedad',
      'model_prediction': 'Predicción del modelo',
      'map_identifier': 'Identificador Mapa',
      'loading': 'Cargando...',
      'location_error': 'Error de ubicación',
      'location_unavailable': 'Ubicación no disponible',
      
      // Resumen
      'measurement_summary': 'Resumen de Mediciones',
      'average_no2': 'Promedio NO2',
      'average_o3': 'Promedio O3',
      'no2_trend': 'Tendencia de NO2',
      'o3_trend': 'Tendencia de O3',
      'today': 'Hoy',
      
      // Recursos
      'export_to_csv': 'Exportar a CSV',
      'export_records': 'Exportar Registros a CSV',
      'select_date_load': 'Seleccione una fecha o rango para cargar los registros y luego expórtelos en formato CSV.',
      'no_date_selected': 'Ninguna fecha seleccionada',
      'records_loaded': 'registros cargados y listos para exportar.',
      'no_data_to_export': 'No hay datos para exportar. Por favor, seleccione una fecha y cargue los datos.',
      'download_started': 'La descarga del archivo CSV ha comenzado.',
      'error_loading_data': 'Error al cargar los datos',
      
      // Popup
      'nearby_group': 'Grupo de',
      'nearby_records': 'registros cercanos',
      'prediction': 'Predicción',
      'average': 'promedio',
      'last_update': 'Última actualización',
      
      // Botones
      'select': 'Seleccionar',
      'load_last_day': 'Cargar último día con registros',
      'cancel': 'Cancelar',
      'accept': 'Aceptar',
      'close': 'Cerrar',
      
      // Otros
      'historical_data': 'Datos Históricos',
      'real_time_data': 'Datos en Tiempo Real',
      'statistics': 'Estadísticas',
      'no_records': 'No se encontraron registros',
      'no_data_for_date': 'No hay datos para la fecha seleccionada',
      'unhealthy_for_sensitive': 'Poco Saludable',
      'not_available': 'No disponible',
      'active_status': 'Estado Activo',
      'inactive_status': 'Estado Desactivado',
      'date_label': 'Fecha:',
      'range_label': 'Rango:',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Método de acceso directo
  String operator [](String key) => translate(key);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
