import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_aiq/presentation/providers/language_provider.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isEnglish = languageProvider.isEnglish;
        
        return GestureDetector(
          onTap: () {
            languageProvider.toggleLanguage();
          },
      child: Container(
        width: 95,
        height: 38,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 212, 243, 225),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            // ---------------------------
            // TEXTO (se mueve al lado opuesto de la bandera)
            // ---------------------------
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              // cuando bandera va a la derecha, texto va a la izquierda
              left: isEnglish ? 12 : null,
              right: isEnglish ? null : 12,
              top: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  isEnglish ? "En" : "Es",
                  key: ValueKey(isEnglish),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ---------------------------
            // BANDERA
            // ---------------------------
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              // bandera va al lado opuesto del texto
              right: isEnglish ? 8 : null,
              left: isEnglish ? null : 8,
              top: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 14,
                backgroundImage: AssetImage(
                  isEnglish
                      ? "assets/images/us.png"
                      : "assets/images/es.png",
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
