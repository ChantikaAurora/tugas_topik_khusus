class Report {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String reportType; // "hilang" atau "temuan"
  final String userId;
  final String? photoUrl;

  Report({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.reportType,
    required this.userId,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'report_type': reportType,
        'user_id': userId,
        'photo_url': photoUrl,
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
      );
}
