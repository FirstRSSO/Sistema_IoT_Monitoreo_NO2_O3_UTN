import 'package:fluro/fluro.dart';
import 'package:flutter_web_aiq/presentation/pages/counter_page.dart';
import 'package:flutter_web_aiq/presentation/pages/historial_page.dart';
import 'package:flutter_web_aiq/presentation/pages/history_page.dart';
import 'package:flutter_web_aiq/presentation/pages/map_page.dart';
import 'package:flutter_web_aiq/presentation/pages/resources_page.dart';
import 'package:flutter_web_aiq/presentation/pages/view_404_page.dart';
import 'package:latlong2/latlong.dart';

class Flurorouter {
  static final FluroRouter router = FluroRouter();

  static String rootRoute = '/';
  static String mapRoute = '/map';
  static String mapRouteQ = '/map/marker/:day/:month/:year/:lat/:lng';
  static String historyRoute = '/history';
  static String registerRoute = '/register';
  static String resourcesRoute = '/resources';
//Auth Route
  static String loginRoute = '/auth/login';
  // static String registerRoute = '/auth/register';

  //Dashboard Route
  static String dashboardRoute = '/dashboard';
  static String iconsRoute = '/dashboard/icons';
  static String blankRoute = '/dashboard/blank';

  static void configureRoutes() {
    router.define(rootRoute,
        handler: _mapPageHandler, transitionType: TransitionType.none);
    router.define(mapRoute,
        handler: _mapPageHandler, transitionType: TransitionType.none);
    router.define(mapRouteQ,
        handler: _mapPageHandler, transitionType: TransitionType.none);
    router.define(historyRoute,
        handler: _historyPageHandler, transitionType: TransitionType.none);
    router.define(registerRoute,
        handler: _registerPageHandler, transitionType: TransitionType.none);
    router.define(resourcesRoute,
        handler: _resourcesPageHandler, transitionType: TransitionType.none);

    router.define(
      '/stateful',
      handler: _counterHandler,
      transitionType: TransitionType.fadeIn,
      transitionDuration: Duration(milliseconds: 200),
    );
    // router.define(rootRoute, handler: AdminHandlers.login, transitionType: TransitionType.none);
    // router.define(loginRoute, handler: AdminHandlers.login, transitionType: TransitionType.none);
    // router.define(registerRoute, handler: AdminHandlers.register, transitionType: TransitionType.none);

    // router.define(dashboardRoute, handler: DashboardHandlers.dashboard, transitionType: TransitionType.fadeIn);
    // router.define(iconsRoute, handler: DashboardHandlers.icons, transitionType: TransitionType.fadeIn);
    // router.define(blankRoute, handler: DashboardHandlers.blank, transitionType: TransitionType.fadeIn);
    router.notFoundHandler = _noPageFoundHandlers;
  }

  static Handler _counterHandler =
      new Handler(handlerFunc: (context, params) => CounterPage());
  static Handler _noPageFoundHandlers =
      new Handler(handlerFunc: (context, params) => View404Page());
      
  static Handler _mapPageHandler = new Handler(handlerFunc: (context, params) {
    if (params.isNotEmpty) {
      final day = params['day']?.first;
      final month = params['month']?.first;
      final year = params['year']?.first;
      final lat = params['lat']?.first;
      final lng = params['lng']?.first;

      if (day != null && month != null && year != null && lat != null && lng != null) {
        final fecha = DateTime(
          int.parse(year),
          int.parse(month),
          int.parse(day),
        );
        final locations = LatLng(
          double.parse(lat),
          double.parse(lng),
        );
        return MapPage(fecha: fecha, locations: locations);
      }
    }
    return MapPage();
  });

  static Handler _historyPageHandler =
      new Handler(handlerFunc: (context, params) => HistoryPage());
  static Handler _registerPageHandler =
      new Handler(handlerFunc: (context, params) => HistorialPage());
  static Handler _resourcesPageHandler =
      new Handler(handlerFunc: (context, params) => ResourcesPage());
  //Auth Routes
}
