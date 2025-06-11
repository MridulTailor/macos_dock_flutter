# MacOS Dock in Flutter

An implementation of the macOS dock with smooth animation, magnification effects, and drag-to-reorder functionality — all built with clean, generic widgets in Flutter.

- Realistic magnification effect using `lerpDouble` interpolation
- Smooth animations with `TweenAnimationBuilder` and `AnimatedContainer`
- Drag and drop to reorder items with clean transitions
- Proximity-based scaling that affects neighboring items
- Fluid transitions with customizable easing curves
- Clean generic widget implementation using type parameters

---

## How It Works

- Generic widget implementation with `Dock<T>` that works with any type
- Custom scaling algorithm that magnifies icons based on hover position
- Transform matrices for precise positioning and scaling
- Position tracking with `TweenAnimationBuilder` for smooth reordering
- `InheritedWidget` pattern for efficient UI updates

### Example Generic Widget Code

```dart
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
  // Implementation here...
}
```

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/MridulTailor/macos_dock_flutter.git

# Navigate to the project
cd macos_dock_flutter

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

## 📄 License

[MIT](LICENSE)
