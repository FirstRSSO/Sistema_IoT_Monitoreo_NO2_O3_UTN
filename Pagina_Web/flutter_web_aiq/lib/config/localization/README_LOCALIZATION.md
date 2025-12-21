# Guía de Uso de Internacionalización

## Cómo usar las traducciones en tu código

### 1. En cualquier Widget
```dart
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';

class MiWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.translate('key'));
    // o usando el operador []
    return Text(l10n['key']);
  }
}
```

### 2. Claves disponibles

#### Menú
- `map` - Mapa / Map
- `measurements` - Mediciones / Measurements  
- `resources` - Recursos / Resources

#### Mapa
- `no_data` - No hay datos aún / No data yet
- `no_data_selected_date` - No hay datos recolectados en la fecha seleccionada
- `reload_map` - Recargar mapa con último registro
- `select_day` - Seleccionar día / Select day
- `select_range` - Seleccionar por rango / Select range
- `last_registered_day` - Último día registrado
- `view_history` - Ver registro histórico

#### Calidad del aire
- `good` - Bueno / Good
- `moderate` - Moderado / Moderate
- `unhealthy` - Insalubre / Unhealthy
- `very_unhealthy` - Muy Insalubre / Very Unhealthy
- `hazardous` - Peligroso / Hazardous
- `air_quality` - Calidad del Aire / Air Quality

#### Mediciones
- `location` - Ubicación / Location
- `date` - Fecha / Date
- `time` - Hora / Time
- `temperature` - Temperatura / Temperature
- `humidity` - Humedad / Humidity
- `model_prediction` - Predicción del modelo
- `loading` - Cargando... / Loading...

#### Recursos
- `export_to_csv` - Exportar a CSV / Export to CSV
- `export_records` - Exportar Registros a CSV
- `no_data_to_export` - No hay datos para exportar
- `download_started` - La descarga del archivo CSV ha comenzado

#### Botones
- `select` - Seleccionar / Select
- `cancel` - Cancelar / Cancel
- `accept` - Aceptar / Accept
- `close` - Cerrar / Close

### 3. Agregar nuevas traducciones

Edita el archivo `app_localizations.dart` y agrega las claves en ambos idiomas:

```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'tu_nueva_clave': 'Your new text in English',
  },
  'es': {
    'tu_nueva_clave': 'Tu nuevo texto en Español',
  },
};
```

### 4. Cambiar idioma programáticamente

```dart
import 'package:provider/provider.dart';
import 'package:flutter_web_aiq/presentation/providers/language_provider.dart';

// Para cambiar a un idioma específico
context.read<LanguageProvider>().setLocale(Locale('en'));
context.read<LanguageProvider>().setLocale(Locale('es'));

// Para alternar entre idiomas
context.read<LanguageProvider>().toggleLanguage();

// Para obtener el idioma actual
final isEnglish = context.read<LanguageProvider>().isEnglish;
final isSpanish = context.read<LanguageProvider>().isSpanish;
```

### 5. El botón de cambio de idioma

Ya está implementado en `custom_app_menu.dart` y funcionará automáticamente.
Al hacer clic, todos los textos traducidos en la app se actualizarán instantáneamente.
