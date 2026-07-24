class SocietyNotice {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const SocietyNotice({required this.id, required this.title, required this.message, required this.createdAt});

  factory SocietyNotice.fromJson(Map<String, dynamic> json) => SocietyNotice(
        id: json['_id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
