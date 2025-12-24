class SensorData {
  final double temp;
  final int humidity;
  final int soil;
  final int light;

  SensorData({
    required this.temp,
    required this.humidity,
    required this.soil,
    required this.light,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      temp: (map['temp'] as num).toDouble(),
      humidity: (map['humidity'] as num).toInt(),
      soil: (map['soil'] as num).toInt(),
      light: (map['light'] as num?)?.toInt() ?? 0, 
    );
  }
}
