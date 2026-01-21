/// Model representing the generation configuration
class GenerationConfig {
  final String? aspectRatio;
  final String? imageSize;
  final String? proxy;

  const GenerationConfig({
    this.aspectRatio,
    this.imageSize,
    this.proxy,
  });

  /// Create a copy of this config with specified fields replaced
  GenerationConfig copyWith({
    String? aspectRatio,
    String? imageSize,
    String? proxy,
  }) {
    return GenerationConfig(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      imageSize: imageSize ?? this.imageSize,
      proxy: proxy ?? this.proxy,
    );
  }

  /// Convert to map representation for compatibility with existing code
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (aspectRatio != null) map['aspectRatio'] = aspectRatio;
    if (imageSize != null) map['imageSize'] = imageSize;
    if (proxy != null) map['proxy'] = proxy;
    return map;
  }

  /// Create from map representation
  static GenerationConfig fromMap(Map<String, dynamic> map) {
    return GenerationConfig(
      aspectRatio: map['aspectRatio'] as String?,
      imageSize: map['imageSize'] as String?,
      proxy: map['proxy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationConfig &&
          runtimeType == other.runtimeType &&
          aspectRatio == other.aspectRatio &&
          imageSize == other.imageSize &&
          proxy == other.proxy;

  @override
  int get hashCode => aspectRatio.hashCode ^ imageSize.hashCode ^ proxy.hashCode;

  @override
  String toString() => 'GenerationConfig{aspectRatio: $aspectRatio, imageSize: $imageSize, proxy: $proxy}';
}