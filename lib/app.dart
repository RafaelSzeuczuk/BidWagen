import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'views/home_view.dart';

class AplicativoBidWagen extends StatelessWidget {
  const AplicativoBidWagen({super.key});

  static const fundo = Color(0xFF101010);
  static const surface = Color(0xFF1B1B1B);
  static const superficieAlta = Color(0xFF252525);
  static const outline = Color(0xFF4A4A4A);
  static const primary = Color(0xFFD32F2F);
  static const primariaEscura = Color(0xFFB71C1C);
  static const textoSuaveSobreSuperficie = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF5F1515),
      onPrimaryContainer: const Color(0xFFFFDAD6),
      secondary: const Color(0xFFBDBDBD),
      surface: surface,
      surfaceContainerHighest: superficieAlta,
      outline: outline,
    );

    return MaterialApp(
      title: 'BidWagen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: esquema,
        scaffoldBackgroundColor: fundo,
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(
          backgroundColor: fundo,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, height: 1.35),
          bodyMedium: TextStyle(fontSize: 14, height: 1.35),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: superficieAlta,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: textoSuaveSobreSuperficie),
          hintStyle: const TextStyle(color: Color(0xFF858585)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 1,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF303030)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Colors.white,
            side: const BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.all(10),
            foregroundColor: Colors.white70,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: superficieAlta,
          behavior: SnackBarBehavior.floating,
          contentTextStyle: const TextStyle(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: Consumer<ServicoAutenticacao>(
        builder: (_, autenticacao, __) => StreamBuilder(
          stream: autenticacao.alteracoesDeAutenticacao,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            return snapshot.hasData ? const TelaInicial() : const TelaLogin();
          },
        ),
      ),
    );
  }
}
