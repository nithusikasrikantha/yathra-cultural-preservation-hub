class Connection {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Connection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['_id'] ?? '',
      requesterId: json['requester'] ?? '',
      receiverId: json['receiver'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requester': requesterId,
      'receiver': receiverId,
      'status': status,
    };
  }
}
