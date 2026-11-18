import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Emoji used as an icon, optionally inside a soft tinted circle.
/// Emoji icons match the reference design and are instantly recognisable
/// for low-literacy users.
class EmojiIcon extends StatelessWidget {
  const EmojiIcon(this.emoji, {super.key, this.size = 24, this.background, this.boxSize, this.semanticLabel});

  final String emoji;
  final double size;
  final Color? background;
  final double? boxSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      emoji,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: size, height: 1.15, fontFamily: null),
      semanticsLabel: semanticLabel,
    );
    if (background == null) return text;
    final box = boxSize ?? size * 1.9;
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: text,
    );
  }
}

/// White rounded card with a soft shadow (the main building block of the UI).
class FasalCard extends StatelessWidget {
  const FasalCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.color = AppColors.surface,
    this.onTap,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.shadow = true,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;
  final bool shadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.2),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0xFF1F3B1F).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// Small pill label: "Now", "Important", "Sample", severity, etc.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.color = AppColors.primary, this.background, this.filled = true});

  final String label;
  final Color color;
  final Color? background;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? (background ?? color) : (background ?? color.withValues(alpha: 0.12)),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: filled && background == null ? Colors.white : color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Section heading with optional trailing link ("Crop calendar →").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction, this.padding});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dir = Directionality.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.titleLarge)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                '$actionLabel ${dir == TextDirection.rtl ? '←' : '→'}',
                style: t.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft peach note used for disclaimers ("Sample guidance…").
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.emoji = 'ℹ️', this.color = AppColors.secondaryContainer, this.textColor});

  final String text;
  final String emoji;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiIcon(emoji, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor ?? const Color(0xFF7A5A3F)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented progress like the reference hero card (one segment per stage).
class StageSegments extends StatelessWidget {
  const StageSegments({super.key, required this.count, required this.current, this.onDark = true});

  final int count;
  final int current;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillAll,
                color: i <= current
                    ? (onDark ? Colors.white : AppColors.primary)
                    : (onDark ? Colors.white.withValues(alpha: 0.28) : AppColors.surfaceMuted),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Round check button used for tasks (large touch target).
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, required this.onTap, required this.semanticLabel});

  final bool checked;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: AppSpacing.minTouch,
          height: AppSpacing.minTouch,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.primary : Colors.white,
                border: Border.all(color: checked ? AppColors.primary : AppColors.border, width: 1.6),
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 20, color: Colors.white) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Constrains page content on wide screens and applies page padding.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding, this.controller, this.onRefresh});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: children,
    );
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, color: AppColors.primary, child: list);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: list,
      ),
    );
  }
}

/// Vertical gap helper.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
