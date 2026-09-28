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

  // Factory constructor dari JSON dengan penanganan null yang aman
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // Mengubah ke int dengan aman, jika null atau tidak ada maka default ke 0
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      // Mengubah ke String dengan aman, jika null atau tidak ada maka default ke String kosong ''
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}