import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<IconData>(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (item) => DockItem(
              icon: item,
              color: Colors.primaries[item.hashCode % Colors.primaries.length],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _DockItemState extends State<DockItem> {
  @override
  Widget build(BuildContext context) {
    final DockInheritedWidget? dockWidget =
        context.dependOnInheritedWidgetOfExactType<DockInheritedWidget>();
    final index = dockWidget?.index ?? 0;
    final scale = dockWidget?.getScaledSize(index) ?? 1.0;
    final translation = dockWidget?.getTranslationY(index) ?? 0.0;

    return Draggable<IconData>(
      data: widget.icon,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48),
          height: 48,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(scale)
          ..translate(0.0, translation),
        margin: index == dockWidget?.hoveredIndex
            ? const EdgeInsets.only(right: 25)
            : EdgeInsets.zero,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48),
          height: 48,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: scale,
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DockInheritedWidget extends InheritedWidget {
  const DockInheritedWidget({
    super.key,
    required super.child,
    required this.index,
    required this.hoveredIndex,
    required this.getScaledSize,
    required this.getTranslationY,
  });

  final int index;
  final int? hoveredIndex;
  final double Function(int) getScaledSize;
  final double Function(int) getTranslationY;

  @override
  bool updateShouldNotify(DockInheritedWidget oldWidget) {
    return oldWidget.hoveredIndex != hoveredIndex || oldWidget.index != index;
  }
}

class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>>
    with SingleTickerProviderStateMixin {
  late final List<T?> _items = widget.items.map((item) => item as T?).toList();
  int? hoveredIndex;
  int? draggedIndex;
  bool isDragging = false;
  T? draggedItem;
  bool isOutsideDock = false;

  static const double baseItemScale = 1.0;
  static const double maxItemScale = 1.5;
  static const double nonHoveredMaxScale = 1.2;
  static const double baseTranslationY = 0.0;
  static const double maxTranslationY = -24.0;
  static const double nonHoveredMaxTranslationY = -12.0;
  static const int itemsAffected = 2;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  final List<GlobalKey> _itemKeys = [];
  final Map<Key, Offset> _oldPositions = {};
  final Map<Key, Offset> _newPositions = {};

  @override
  void initState() {
    super.initState();
    _itemKeys
        .addAll(List.generate(widget.items.length, (index) => GlobalKey()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get middleIndex => (_items.length ~/ 2);

  void _savePositions() {
    _oldPositions.clear();
    for (var key in _itemKeys) {
      final RenderBox? box =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        _oldPositions[key] = box.localToGlobal(Offset.zero);
      }
    }
  }

  void _animatePositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newPositions.clear();
      for (var key in _itemKeys) {
        final RenderBox? box =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          _newPositions[key] = box.localToGlobal(Offset.zero);
        }
      }
      setState(() {});
    });
  }

  void onDraggedOutside() {
    if (draggedIndex != null && draggedItem != null) {
      setState(() {
        isOutsideDock = true;
        _savePositions();
        _items.removeAt(draggedIndex!);
        _itemKeys.removeAt(draggedIndex!);
        _animatePositions();
      });
    }
  }

  void insertDraggedItem(int index) {
    if (draggedItem != null) {
      _savePositions();
      setState(() {
        isOutsideDock = false;
        // Insert the item at the target position
        _items.insert(index, draggedItem);
        _itemKeys.insert(index, GlobalKey());
        draggedItem = null;
        draggedIndex = null;
      });
      _animatePositions();
      _controller.forward(from: 0);
    }
  }

  double getPropertyValue(
    int index,
    double baseValue,
    double maxValue,
    double nonHoveredMaxValue,
  ) {
    if (hoveredIndex == null) return baseValue;
    final difference = (hoveredIndex! - index).abs();
    if (difference == 0) return maxValue;
    if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      return lerpDouble(baseValue, nonHoveredMaxValue, ratio) ?? baseValue;
    }
    return baseValue;
  }

  double getScaledSize(int index) {
    return getPropertyValue(
      index,
      baseItemScale,
      maxItemScale,
      nonHoveredMaxScale,
    );
  }

  double getTranslationY(int index) {
    return getPropertyValue(
      index,
      baseTranslationY,
      maxTranslationY,
      nonHoveredMaxTranslationY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          height: 72.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 64.0 * _items.length.toDouble(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final itemKey = _itemKeys[index];

              Offset? oldPosition = _oldPositions[itemKey];
              Offset? newPosition = _newPositions[itemKey];
              Offset offset = Offset.zero;

              if (oldPosition != null && newPosition != null) {
                offset = oldPosition - newPosition;
              }

              return TweenAnimationBuilder<Offset>(
                key: itemKey,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ),
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset,
                    child: DragTarget<T>(
                      onWillAcceptWithDetails: (data) {
                        draggedIndex = index;
                        draggedItem = data.data;
                        isDragging = true;
                        return true;
                      },
                      onLeave: (data) {
                        if (isDragging && !isOutsideDock) {
                          onDraggedOutside();
                        }
                      },
                      onAcceptWithDetails: (data) {
                        insertDraggedItem(index);
                        isDragging = false;
                      },
                      builder: (context, candidates, rejects) {
                        if (item == null) {
                          return const SizedBox(width: 0);
                        }
                        return MouseRegion(
                          onEnter: (_) => setState(() => hoveredIndex = index),
                          onExit: (_) => setState(() => hoveredIndex = null),
                          child: DockInheritedWidget(
                            index: index,
                            hoveredIndex: hoveredIndex,
                            getScaledSize: getScaledSize,
                            getTranslationY: getTranslationY,
                            child: widget.builder(item),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == null || b == null) {
    return null;
  }
  return a + (b - a) * t;
}
