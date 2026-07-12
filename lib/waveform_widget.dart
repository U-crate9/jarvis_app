import 'dart:math';
import 'package:flutter/material.dart';

/// Animated vertical bars that pulse like an audio waveform — the visual
/// signature from the reference video, in place of a plain static orb.
/// Bars move gently when idle and animate more energetically when [active].
class WaveformIndicator extends StatefulWidget {
  final bool active;
  final Color color;
  final int barCount;

  const WaveformIndicator({
    super.key,
    required this.active,
    this.color = const Color(0xFF00E5FF),
    this.barCount = 5,
  });

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rand = Random();
  late List<double> _seeds;

  @override
  void initState() {
    super.initState();
    _seeds = List.generate(widget.barCount, (_) => _rand.nextDouble());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(widget.active ? 0.35 : 0.15),
                blurRadius: 45,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = _seeds[i] * 2 * pi;
              final t = _controller.value * 2 * pi;
              final wobble = (sin(t + phase) + 1) / 2; // 0..1
              final minH = widget.active ? 10.0 : 6.0;
              final maxH = widget.active ? 58.0 : 22.0;
              final height = minH + wobble * (maxH - minH);
              return Container(
                width: 6,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: widget.color.withOpacity(0.7), blurRadius: 6),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
