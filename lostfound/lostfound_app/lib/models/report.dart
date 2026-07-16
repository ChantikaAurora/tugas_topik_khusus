class Report {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String reportType; // "hilang" atau "temuan"
  final String? userId; // diisi backend dari token JWT, bukan dari client
  final String? photoUrl;
  final double? latitude;
  final double? longitude;

  Report({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.reportType,
    this.userId,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'report_type': reportType,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['_id']?.toString(),
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? '',
        location: json['location'] ?? '',
        reportType: json['report_type'] ?? '',
        userId: json['user_id'] ?? '',
        photoUrl: json['photo_url'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
