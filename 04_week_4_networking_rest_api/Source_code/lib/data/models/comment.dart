class Comment {
  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String parseString(dynamic value) {
      if (value is String) return value;
      return value?.toString() ?? '';
    }

    return Comment(
      postId: parseInt(json['postId']),
      id: parseInt(json['id']),
      name: parseString(json['name']),
      email: parseString(json['email']),
      body: parseString(json['body']),
    );
  }
}