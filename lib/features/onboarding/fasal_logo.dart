import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// FASAL brand mark: wheat sheaf in a rounded green tile.
class FasalLogo extends StatelessWidget {
  const FasalLogo({super.key, this.size = 90, this.inverted = false});

  final double size;

  /// White tile (for use on the green splash background).
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fasal',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverted ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: (inverted ? Colors.black : AppColors.primary).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          '🌾',
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: size * 0.52),
        ),
      ),
    );
  }
}
