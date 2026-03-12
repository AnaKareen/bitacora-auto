import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Card con efecto de presión (scale down) al tocar.
/// Úsalo en cualquier card de la app envolviendo su contenido.
///
/// Ejemplo:
/// ```dart
/// AnimatedCard(
///   onTap: () => Navigator.push(...),
///   child: MiContenido(),
/// )
/// ```
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Escala mínima al presionar (default 0.97 — sutil y premium)
  final double scaleMin;

  /// Duración de la animación de bajada
  final Duration durationDown;

  /// Duración de la animación de subida (regreso)
  final Duration durationUp;

  /// Si true, dispara haptic feedback al presionar
  final bool haptic;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleMin      = 0.97,
    this.durationDown  = const Duration(milliseconds: 80),
    this.durationUp    = const Duration(milliseconds: 200),
    this.haptic        = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.durationDown,
      reverseDuration: widget.durationUp,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleMin).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.haptic) HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel()            => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:        widget.onTap,
      onLongPress:  widget.onLongPress,
      onTapDown:    _onTapDown,
      onTapUp:      _onTapUp,
      onTapCancel:  _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}