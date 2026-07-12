import 'package:flutter/material.dart';

enum PanelCorner { topLeft, topRight, bottomLeft, bottomRight }

/// A small draggable, dockable panel — snaps to whichever screen corner
/// it's dragged nearest to, and double-tap toggles between a small
/// docked card and a large expanded view. This is how the "multiple
/// panels" look is achieved on a single mobile screen: panels dock to
/// corners by default, and you pull the one you want into focus.
class DockablePanel extends StatefulWidget {
  final String title;
  final Widget child;
  final PanelCorner initialCorner;
  final Color accentColor;

  const DockablePanel({
    super.key,
    required this.title,
    required this.child,
    required this.initialCorner,
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  State<DockablePanel> createState() => _DockablePanelState();
}

class _DockablePanelState extends State<DockablePanel> {
  PanelCorner _corner = PanelCorner.topLeft;
  bool _expanded = false;
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  static const double _dockedWidth = 150;
  static const double _dockedHeight = 110;
  static const double _margin = 12;
  static const double _topMargin = 100; // leave room for the app bar / orb

  @override
  void initState() {
    super.initState();
    _corner = widget.initialCorner;
  }

  Offset _cornerOffset(PanelCorner corner, Size screenSize, double width, double height) {
    switch (corner) {
      case PanelCorner.topLeft:
        return Offset(_margin, _topMargin);
      case PanelCorner.topRight:
        return Offset(screenSize.width - width - _margin, _topMargin);
      case PanelCorner.bottomLeft:
        return Offset(_margin, screenSize.height - height - _margin - 80);
      case PanelCorner.bottomRight:
        return Offset(screenSize.width - width - _margin, screenSize.height - height - _margin - 80);
    }
  }

  PanelCorner _nearestCorner(Offset position, Size screenSize) {
    final isLeft = position.dx < screenSize.width / 2;
    final isTop = position.dy < screenSize.height / 2;
    if (isLeft && isTop) return PanelCorner.topLeft;
    if (!isLeft && isTop) return PanelCorner.topRight;
    if (isLeft && !isTop) return PanelCorner.bottomLeft;
    return PanelCorner.bottomRight;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = _expanded ? screenSize.width - 32 : _dockedWidth;
    final height = _expanded ? screenSize.height * 0.6 : _dockedHeight;

    final baseOffset = _expanded
        ? Offset(16, screenSize.height * 0.18)
        : _cornerOffset(_corner, screenSize, width, height);

    final position = _dragging ? baseOffset + _dragOffset : baseOffset;

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: GestureDetector(
        onDoubleTap: () => setState(() => _expanded = !_expanded),
        onPanStart: (_) => setState(() {
          _dragging = true;
          _dragOffset = Offset.zero;
        }),
        onPanUpdate: (details) => setState(() {
          _dragOffset += details.delta;
        }),
        onPanEnd: (_) {
          if (_expanded) {
            setState(() => _dragging = false);
            return;
          }
          final released = baseOffset + _dragOffset;
          final newCorner = _nearestCorner(
            Offset(released.dx + _dockedWidth / 2, released.dy + _dockedHeight / 2),
            screenSize,
          );
          setState(() {
            _corner = newCorner;
            _dragging = false;
            _dragOffset = Offset.zero;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F1A).withOpacity(0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accentColor.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accentColor),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.close_fullscreen : Icons.open_in_full,
                    size: 12,
                    color: Colors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
