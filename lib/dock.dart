import 'package:flutter/material.dart';

class DockItem extends StatefulWidget {
  const DockItem({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  State<DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<DockItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.5,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  ));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: Draggable<IconData>(
        data: widget.icon,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.color.withOpacity(0.5),
            ),
            child: Icon(widget.icon, color: Colors.white),
          ),
        ),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48),
            height: 48,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.color,
            ),
            child: Center(child: Icon(widget.icon, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  // Added 'extends Object' here
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  // Added 'extends Object' here
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return DragTarget<T>(
            onAcceptWithDetails: (data) {
              setState(() {
                final draggedIndex = _items.indexOf(data.data);
                // Reorder items
                _items.removeAt(draggedIndex);
                _items.insert(index, data.data);
              });
            },
            builder: (context, candidates, rejects) {
              return widget.builder(item);
            },
          );
        }).toList(),
      ),
    );
  }
}
