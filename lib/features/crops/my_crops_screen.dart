import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/basics.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/feedback.dart';

import 'package:fasal_core/models.dart';

import '../../providers/farm_providers.dart';
import '../../widgets/crop_widgets.dart';

class MyCropsScreen extends ConsumerWidget {
  const MyCropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final views = ref.watch(cropViewsProvider);
    final tasks = ref.watch(tasksProvider).value ?? const <FarmTask>[];

    FarmTask? nextFor(String cropId) {
      for (final t in tasks) {
        if (t.cropId == cropId && !t.isDone) return t; // tasks are sorted by date
      }
      return null;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: s.myCrops,
              actions: [HeaderIconButton(icon: Icons.add_rounded, tooltip: s.addCrop, onPressed: context.toAddCrop)],
            ),
            Expanded(
              child: AsyncView(
                value: views,
                onRetry: () => ref.invalidate(cropsProvider),
                loading: const PageBody(children: [SkeletonCard(height: 200), SkeletonCard(height: 200)]),
                data: (list) => PageBody(
                  onRefresh: () async {
                    ref.invalidate(cropsProvider);
                    await ref.read(cropsProvider.future);
                  },
                  children: [
                    if (list.isEmpty)
                      EmptyState(
                        emoji: '🌱',
                        title: s.noCropsTitle,
                        body: s.noCropsBody,
                        actionLabel: s.addCropPlus,
                        onAction: context.toAddCrop,
                      ),
                    for (final v in list) ...[
                      CropListCard(
                        key: Key('cropcard_${v.crop.id}'),
                        view: v,
                        nextTask: nextFor(v.crop.id),
                        onTap: () => context.toCrop(v.crop.id),
                        menu: CropMenu(view: v),
                      ),
                      const Gap(14),
                    ],
                    if (list.isNotEmpty) AddCropDashed(onTap: context.toAddCrop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⋮ menu with Edit / History / Remove (with confirmation).
class CropMenu extends ConsumerWidget {
  const CropMenu({super.key, required this.view, this.afterRemove});

  final CropView view;
  final VoidCallback? afterRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return PopupMenuButton<String>(
      tooltip: s.edit,
      icon: const Icon(Icons.more_vert_rounded),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      onSelected: (v) async {
        switch (v) {
          case 'edit':
            context.pushIn<void>('edit-crop/${view.crop.id}');
          case 'history':
            context.pushIn<void>('history/${view.crop.id}');
          case 'remove':
            await confirmRemoveCrop(context, ref, view, afterRemove: afterRemove);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text('✏️  ${s.editCrop}')),
        PopupMenuItem(value: 'history', child: Text('📒  ${s.cropHistory}')),
        PopupMenuItem(
          value: 'remove',
          child: Text('🗑️  ${s.removeCrop}', style: const TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

Future<void> confirmRemoveCrop(BuildContext context, WidgetRef ref, CropView view, {VoidCallback? afterRemove}) async {
  final s = context.s;
  final ok = await showConfirmDialog(
    context,
    title: s.removeCrop,
    body: s.removeCropBody(view.def.name.of(context.lang)),
    confirmLabel: s.remove,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(cropsProvider.notifier);
  afterRemove?.call(); // e.g. leave the details screen before its crop disappears
  await notifier.remove(view.crop.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s.cropDeleted)));
}

/// Dashed "+ Add your crop" button from the reference.
class AddCropDashed extends StatelessWidget {
  const AddCropDashed({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.lgAll,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: SizedBox(
          height: 58,
          child: Center(
            child: Text(
              context.s.addCropPlus,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
