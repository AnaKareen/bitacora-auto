import 'package:flutter/material.dart';
import 'dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ─── ANIMACIONES ─────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _barCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double>  _logoScale;
  late final Animation<double>  _logoOpacity;
  late final Animation<Offset>  _logoSlide;
  late final Animation<double>  _textOpacity;
  late final Animation<Offset>  _textSlide;
  late final Animation<double>  _barProgress;
  late final Animation<double>  _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Controlador del logo (0.7 s)
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _logoSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // Controlador del texto (0.5 s)
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Barra de carga (1.0 s)
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));

    // Controlador de salida (0.4 s)
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _iniciarSecuencia();
  }

  Future<void> _iniciarSecuencia() async {
    // 1. Logo entra
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoCtrl.forward();

    // 2. Texto entra
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();

    // 3. Barra de carga
    await Future.delayed(const Duration(milliseconds: 150));
    await _barCtrl.forward();

    // 4. Pequeña pausa
    await Future.delayed(const Duration(milliseconds: 300));

    // 5. Fade out y navegar
    await _exitCtrl.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Dashboard(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(
        opacity: _exitOpacity.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        body: SafeArea(
          child: Stack(
            children: [

              // ── FONDO: puntos decorativos ─────────────────────────────
              Positioned(top: -40, right: -40,
                child: _circuloFondo(200, const Color(0x0A3B7BFF))),
              Positioned(bottom: -60, left: -60,
                child: _circuloFondo(250, const Color(0x0A3B7BFF))),
              Positioned(top: 120, left: -30,
                child: _circuloFondo(100, const Color(0x0700C48C))),

              // ── CONTENIDO CENTRAL ─────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo animado
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, __) => FadeTransition(
                        opacity: _logoOpacity,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: _logoWidget(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Nombre + subtítulo animados
                    AnimatedBuilder(
                      animation: _textCtrl,
                      builder: (_, __) => FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(children: [
                            const Text(
                              "Mi Sentra",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Bitácora vehicular",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Barra de progreso
                    AnimatedBuilder(
                      animation: _barProgress,
                      builder: (_, __) => _barraProgreso(_barProgress.value),
                    ),
                  ],
                ),
              ),

              // ── VERSIÓN ABAJO ─────────────────────────────────────────
              Positioned(
                bottom: 24,
                left: 0, right: 0,
                child: AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      "Nissan Sentra 2006",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────────────────────
  Widget _logoWidget() => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D27),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: const Color(0xFF3B7BFF).withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B7BFF).withOpacity(0.25),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.directions_car_rounded,
            color: Color(0xFF3B7BFF),
            size: 52,
          ),
        ),
      );

  Widget _barraProgreso(double progress) => Column(
        children: [
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF3B7BFF)),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress < 0.4
                ? "Iniciando..."
                : progress < 0.8
                    ? "Cargando datos..."
                    : "Listo",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );

  Widget _circuloFondo(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
}