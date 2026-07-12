import 'package:flutter/material.dart';

enum PanelCorner { topLeft, topRight, bottomLeft, bottomRight }

/// A small draggable, dockable HUD-style panel — snaps to whichever screen
/// corner it's dragged nearest to, and double-tap toggles between a small
/// docked card and a large expanded view. Styled with a slight tilt and
/// corner brackets for a sci-fi "control center" look.
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

  static const double _dockedWidth = 158;
  static const double _dockedHeight = 116;
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

  // A tiny tilt per corner gives the "angled card" HUD look from the
  // reference video, without affecting the (unrotated) drag hit-box.
  double _tiltFor(PanelCorner corner) {
    if (_expanded) return 0;
    switch (corner) {
      case PanelCorner.topLeft:
        return -0.035;
      case PanelCorner.topRight:
        return 0.035;
      case PanelCorner.bottomLeft:
        return 0.025;
      case PanelCorner.bottomRight:
        return -0.025;
    }
  }

  Widget _cornerBracket({required bool top, required bool left}) {
    return Positioned(
      top: top ? 4 : null,
      bottom: top ? null : 4,
      left: left ? 4 : null,
      right: left ? null : 4,
      child: SizedBox(
        width: 10,
        height: 10,
        child: Stack(
          children: [
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(width: 10, height: 1.4, color: widget.accentColor.withOpacity(0.8)),
            ),
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(width: 1.4, height: 10, color: widget.accentColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
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
        child: AnimatedRotation(
          turns: _tiltFor(_corner) / (2 * 3.14159265),
          duration: _dragging ? Duration.zero : const Duration(milliseconds: 260),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0B0F1A).withOpacity(0.97),
                  const Color(0xFF0B0F1A).withOpacity(0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.accentColor.withOpacity(0.45), width: 1),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accentColor,
                              boxShadow: [
                                BoxShadow(color: widget.accentColor.withOpacity(0.8), blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: widget.accentColor.withOpacity(0.9),
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            _expanded ? Icons.close_fullscreen : Icons.open_in_full,
                            size: 11,
                            color: Colors.white24,
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Divider(height: 1, color: Colors.white12),
                      ),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontFamily: 'monospace'),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
                _cornerBracket(top: true, left: true),
                _cornerBracket(top: true, left: false),
                _cornerBracket(top: false, left: true),
                _cornerBracket(top: false, left: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
