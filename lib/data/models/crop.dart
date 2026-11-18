import 'dart:math' as math;

import '../../core/utils/date_utils.dart';
import 'crop_definition.dart';
import 'user_profile.dart';

/// A crop the farmer is growing.
class Crop {
  const Crop({
    required this.id,
    required this.cropTypeId,
    this.variety = '',
    required this.sowingDate,
    required this.area,
    this.areaUnit = AreaUnit.acre,
    this.fieldName = '',
    this.seedKg,
    this.location = '',
    required this.createdAt,
  });

  final String id;
  final String cropTypeId;
  final String variety;
  final DateTime sowingDate;
  final double area;
  final AreaUnit areaUnit;
  final String fieldName;
  final double? seedKg;
  final String location;
  final DateTime createdAt;

  Crop copyWith({
    String? cropTypeId,
    String? variety,
    DateTime? sowingDate,
    double? area,
    AreaUnit? areaUnit,
    String? fieldName,
    double? seedKg,
    bool clearSeed = false,
    String? location,
  }) => Crop(
    id: id,
    cropTypeId: cropTypeId ?? this.cropTypeId,
    variety: variety ?? this.variety,
    sowingDate: sowingDate ?? this.sowingDate,
    area: area ?? this.area,
    areaUnit: areaUnit ?? this.areaUnit,
    fieldName: fieldName ?? this.fieldName,
    seedKg: clearSeed ? null : (seedKg ?? this.seedKg),
    location: location ?? this.location,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropTypeId': cropTypeId,
    'variety': variety,
    'sowingDate': sowingDate.toIso8601String(),
    'area': area,
    'areaUnit': areaUnit.name,
    'fieldName': fieldName,
    'seedKg': seedKg,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    cropTypeId: json['cropTypeId'] as String,
    variety: json['variety'] as String? ?? '',
    sowingDate: DateTime.parse(json['sowingDate'] as String),
    area: (json['area'] as num?)?.toDouble() ?? 0,
    areaUnit: AreaUnit.values.asNameMap()[json['areaUnit']] ?? AreaUnit.acre,
    fieldName: json['fieldName'] as String? ?? '',
    seedKg: (json['seedKg'] as num?)?.toDouble(),
    location: json['location'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Derived, read-only view of where a crop is in its lifecycle.
class CropProgress {
  CropProgress._({
    required this.day,
    required this.stageIndex,
    required this.fraction,
    required this.harvestStart,
    required this.harvestEnd,
    required this.notSownYet,
    required this.readyForHarvest,
  });

  /// Days since sowing (0 on sowing day). Negative if sowing is in the future.
  final int day;
  final int stageIndex;

  /// 0..1 through the whole crop duration.
  final double fraction;
  final DateTime harvestStart;
  final DateTime harvestEnd;
  final bool notSownYet;
  final bool readyForHarvest;

  factory CropProgress.of(Crop crop, CropDefinition def, {DateTime? today}) {
    final now = AppDates.dateOnly(today ?? DateTime.now());
    final sown = AppDates.dateOnly(crop.sowingDate);
    final day = now.difference(sown).inDays;

    var stageIndex = 0;
    for (var i = 0; i < def.stages.length; i++) {
      if (day >= def.stages[i].startDay) stageIndex = i;
    }
    final last = def.stages.last;
    final double fraction = (day / def.durationDays).clamp(0.0, 1.0).toDouble();
    // Harvest window: start of the final stage's last third to ~2 weeks after.
    final harvestStartDay = math.max(last.startDay, def.durationDays - 10);
    return CropProgress._(
      day: day,
      stageIndex: day < 0 ? 0 : stageIndex,
      fraction: fraction,
      harvestStart: sown.add(Duration(days: harvestStartDay)),
      harvestEnd: sown.add(Duration(days: def.durationDays + 5)),
      notSownYet: day < 0,
      readyForHarvest: day >= harvestStartDay,
    );
  }
}
