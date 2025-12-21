import 'package:flutter/material.dart';

class TableMapProvider extends ChangeNotifier {
  static late AnimationController menuController;
  static late Animation<double> movement;
  static late Animation<double> opacity;

  static bool isOpen = false;

  static void initAnimations(TickerProvider vsync) {
    menuController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );

    movement = Tween<double>(begin: -850, end: 0).animate(
      CurvedAnimation(parent: menuController, curve: Curves.easeInOut),
    );

    opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: menuController, curve: Curves.easeInOut),
    );
  }

  String _currentPage = '';
  String get currentPage => _currentPage;

  void setCurrentPage(String routeName) {
    _currentPage = routeName;
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  static void openMenu() {
    isOpen = true;
    menuController.forward();
  }

  static void closeMenu() {
    isOpen = false;
    menuController.reverse();
  }

  static void toggleMenu() {
    if (isOpen) {
      menuController.reverse();
    } else {
      menuController.forward();
    }
    isOpen = !isOpen;
  }
}
