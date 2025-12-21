import 'package:flutter/material.dart';
import 'package:flutter_web_aiq/locator.dart';
import 'package:flutter_web_aiq/config/services/navigation_service.dart';
import 'package:flutter_web_aiq/presentation/shared/custom_flat_button.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_web_aiq/presentation/shared/widgets/language_toggle_button.dart';
import 'package:flutter_web_aiq/config/localization/app_localizations.dart';

class CustomAppMenu extends StatelessWidget {
  const CustomAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: ( _ , constraints) {
      return (constraints.maxWidth > 520)
              ? _TabletDesktopMenu()
              : _MobileMenu();
    },
    );
  }
}

class _TabletDesktopMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      // width: double.infinity,
      width: size.width,
      // color: Colors.red,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 50,
            // height: 50,
          ),
          const SizedBox(
            width: 10,
          ),
          CustomFlatButton(
            text: l10n.translate('map'),
            onPressed: () {
              locator<NavigationService>().navigateTo('/map');
            },
            color: Colors.black,
          ),
          const SizedBox(
            width: 7,
          ),
          CustomFlatButton(
            text: l10n.translate('measurements'),
            onPressed: () {
              locator<NavigationService>().navigateTo('/history');
              // locator<NavigationService>().navigateTo('/404');
            },
            color: Colors.black,
          ),
          const SizedBox(
            width: 7,
          ),
          CustomFlatButton(
            text: l10n.translate('resources'),
            onPressed: () {
              locator<NavigationService>().navigateTo('/resources');
            },
            color: Colors.black,
          ),
          Spacer(),
          LanguageToggleButton(),
          // IconButton(
          //   onPressed: (){}, 
          //   icon: Icon(Icons.settings, color: Colors.black, size: 35),),

        ],
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFlatButton(
            text: 'Contador Stateful',
            // onPressed: () {Navigator.pushNamed(context, '/stateful');
            onPressed: () {
              locator<NavigationService>().navigateTo('/stateful');
            },
            color: Colors.black,
          ),
          const SizedBox(
            width: 10,
          ),
          CustomFlatButton(
            text: 'Contador Provider',
            onPressed: () {
              // locator<NavigationService>().navigateTo('/provider');
            },
            color: Colors.black,
          ),
          const SizedBox(
            width: 10,
          ),
          CustomFlatButton(
            text: 'Otra pagina',
            onPressed: () {
              // locator<NavigationService>().navigateTo('/404');
            },
            color: Colors.black,
          ),
          const SizedBox(
            width: 10,
          ),
          IconButton(
            onPressed: (){}, 
            icon: Icon(Icons.settings, color: Colors.black, size: 35),),
        ],
      ),
    );
  }
}
