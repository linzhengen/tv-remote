enum TvBrand {
  panasonic,
  samsung,
  lg,
  sony,
}

class TvDeviceInfo {
  final String name;
  final String ipAddress;
  final TvBrand brand;
  final String? modelName;
  final int port;

  const TvDeviceInfo({
    required this.name,
    required this.ipAddress,
    required this.brand,
    this.modelName,
    this.port = 55000,
  });

  factory TvDeviceInfo.fromJson(Map<String, dynamic> json) {
    return TvDeviceInfo(
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      brand: TvBrand.values.byName(json['brand'] as String),
      modelName: json['modelName'] as String?,
      port: json['port'] as int? ?? 55000,
    );
  }

  TvDeviceInfo copyWith({
    String? name,
    String? ipAddress,
    TvBrand? brand,
    String? modelName,
    int? port,
  }) {
    return TvDeviceInfo(
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      brand: brand ?? this.brand,
      modelName: modelName ?? this.modelName,
      port: port ?? this.port,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ipAddress': ipAddress,
      'brand': brand.name,
      'modelName': modelName,
      'port': port,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvDeviceInfo &&
          runtimeType == other.runtimeType &&
          ipAddress == other.ipAddress &&
          port == other.port;

  @override
  int get hashCode => ipAddress.hashCode ^ port.hashCode;
}
