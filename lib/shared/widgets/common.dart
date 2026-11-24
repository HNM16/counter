import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Small uppercase label that introduces a section, with an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.xs, Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title.toUpperCase(), style: text.labelSmall),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// A hairline divider inset to the page gutter.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = Space.gutter, this.endIndent = Space.gutter});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: indent, endIndent: endIndent);
}

/// Calm empty-state block.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, color: c.accent),
          ),
          const SizedBox(height: Space.md),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: Space.lg), action!],
        ],
      ),
    );
  }
}

/// Scales its child down slightly while pressed, for tactile feedback.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.scale = 0.97, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.fast,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Confirmation dialog helper. Returns true when confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: c.textSecondary),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: destructive ? c.danger : c.accent),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

/// A small label/value pair used in stat rows.
class StatPair extends StatelessWidget {
  const StatPair({super.key, required this.value, required this.label, this.alignEnd = false, this.valueColor});

  final String value;
  final String label;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: text.headlineSmall!.copyWith(color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}
