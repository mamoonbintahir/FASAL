enum AreaUnit { acre, kanal, hectare }

/// Conversions to acres so different units can be compared/summed.
extension AreaUnitX on AreaUnit {
  double toAcres(double value) => switch (this) {
    AreaUnit.acre => value,
    AreaUnit.kanal => value / 8.0,
    AreaUnit.hectare => value * 2.4711,
  };
}

class UserProfile {
  const UserProfile({
    this.name = '',
    required this.district,
    this.province = '',
    this.farmName = '',
    required this.farmArea,
    this.areaUnit = AreaUnit.acre,
  });

  final String name;
  final String district;
  final String province;
  final String farmName;
  final double farmArea;
  final AreaUnit areaUnit;

  bool get hasLocation => district.trim().isNotEmpty;

  String get locationLabel => province.isEmpty ? district : '$district, $province';

  UserProfile copyWith({
    String? name,
    String? district,
    String? province,
    String? farmName,
    double? farmArea,
    AreaUnit? areaUnit,
  }) => UserProfile(
    name: name ?? this.name,
    district: district ?? this.district,
    province: province ?? this.province,
    farmName: farmName ?? this.farmName,
    farmArea: farmArea ?? this.farmArea,
    areaUnit: areaUnit ?? this.areaUnit,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'district': district,
    'province': province,
    'farmName': farmName,
    'farmArea': farmArea,
    'areaUnit': areaUnit.name,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    district: json['district'] as String? ?? '',
    province: json['province'] as String? ?? '',
    farmName: json['farmName'] as String? ?? '',
    farmArea: (json['farmArea'] as num?)?.toDouble() ?? 0,
    areaUnit: AreaUnit.values.asNameMap()[json['areaUnit']] ?? AreaUnit.acre,
  );
}
