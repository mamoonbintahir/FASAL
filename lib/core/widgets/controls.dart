import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'basics.dart';

/// Big green primary action button (58px tall, full width by default).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.color = AppColors.primary,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final button = Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        boxShadow: enabled
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
      child: Material(
        color: enabled ? color : color.withValues(alpha: 0.45),
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: AppSpacing.buttonHeight,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.6, color: foreground),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Outlined / tonal secondary button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emoji,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.minTouch,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.4),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[EmojiIcon(emoji!, size: 18), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round white back button from the reference ("←" in a circle).
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, this.onPressed, required this.tooltip});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 46,
            height: 46,
            // Icons.arrow_back auto-mirrors in RTL.
            child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Screen header: optional back button, big title, subtitle and actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.backTooltip = 'Back',
    this.onBack,
    this.actions = const [],
    this.leadingEmoji,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final String backTooltip;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          if (showBack) ...[
            CircleBackButton(onPressed: onBack, tooltip: backTooltip),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leadingEmoji != null) ...[EmojiIcon(leadingEmoji!, size: 24), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(title, style: t.headlineMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small round icon action used in headers (bell, more, …).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(width: 46, height: 46, child: Icon(icon, color: AppColors.textPrimary)),
            ),
          ),
          if (badge > 0)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: AppRadius.pillAll),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Labelled rounded text field matching the reference inputs.
class FasalTextField extends StatelessWidget {
  const FasalTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.autofocus = false,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          autofocus: autofocus,
          style: t.bodyLarge,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: t.bodyLarge?.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, 1.8),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error, 1.8),
            errorStyle: t.bodySmall?.copyWith(color: AppColors.error),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Tappable field that looks like an input but opens a picker (date, district, crop).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.trailing = Icons.expand_more_rounded,
    this.errorText,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData trailing;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.labelMedium),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: hasError ? AppColors.error : AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: t.bodyLarge?.copyWith(color: value == null ? AppColors.textMuted : AppColors.textPrimary),
                    ),
                  ),
                  Icon(trailing, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
            child: Text(errorText!, style: t.bodySmall?.copyWith(color: AppColors.error)),
          ),
      ],
    );
  }
}

/// Pill segmented control ("Fertilizer | Pests", "Activities | Expenses").
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.selected, required this.onChanged, this.emojis});

  final List<String> labels;
  final List<String>? emojis;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.lgAll),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: i == selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (emojis != null) ...[EmojiIcon(emojis![i], size: 16), const SizedBox(width: 6)],
                        Flexible(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              color: i == selected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable emoji tile used in grids (crop choice, expense type, language).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.subtitle,
    this.height = 96,
    this.labelStyle,
  });

  final String label;
  final String? emoji;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primaryContainer : Colors.white,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null) EmojiIcon(emoji!, size: 28),
                if (emoji != null) const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle ?? t.titleSmall,
                ),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of fixed-height children (2 columns on narrow, 3 otherwise).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.minTileWidth = 100, this.spacing = 10});

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / (minTileWidth + spacing)).floor().clamp(2, 4);
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: w, child: child)],
        );
      },
    );
  }
}
