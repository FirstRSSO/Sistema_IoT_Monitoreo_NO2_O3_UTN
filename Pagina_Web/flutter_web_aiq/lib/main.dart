import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';
import 'package:flutter_web_aiq/config/router/router.dart';
import 'package:flutter_web_aiq/config/services/navigation_service.dart';
import 'package:flutter_web_aiq/firebase_options.dart';
import 'package:flutter_web_aiq/locator.dart';
import 'package:flutter_web_aiq/presentation/layouts/main_layout_page.dart';
import 'package:flutter_web_aiq/presentation/providers/language_provider.dart';
import 'package:provider/provider.dart';

Future <void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
  Flurorouter.configureRoutes();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Web AiQ',
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          onGenerateRoute: Flurorouter.router.generator,
          navigatorKey: locator<NavigationService>().navigatorKey,
          builder: (context, childWidget) {
            return MainLayoutPage(
              child: childWidget ?? Container(),
            );
          },
        );
      },
    );
  }
}
