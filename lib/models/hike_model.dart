class HikeModel {
  final int? id;
  final String title;
  final double distance;
  final double elevation;
  final String duration;
  final String date;

  HikeModel({
    this.id,
    required this.title,
    required this.distance,
    required this.elevation,
    required this.duration,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'distance': distance,
      'elevation': elevation,
      'duration': duration,
      'date': date,
    };
  }

  factory HikeModel.fromMap(Map<String, dynamic> map) {
    return HikeModel(
      id: map['id'],
      title: map['title'],
      distance: map['distance'],
      elevation: map['elevation'],
      duration: map['duration'],
      date: map['date'],
    );
  }
}