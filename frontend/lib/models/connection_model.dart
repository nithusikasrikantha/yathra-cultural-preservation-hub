class Connection {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String communityId;
  final String communityName;
  final Map<String, dynamic>? requester;
  final Map<String, dynamic>? receiver;

  Connection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.communityId = '',
    this.communityName = '',
    this.requester,
    this.receiver,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['_id'] ?? '',
      requesterId: _id(json['requester']),
      receiverId: _id(json['receiver']),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      communityId: json['communityId'] ?? '',
      communityName: json['communityName'] ?? '',
      requester: json['requester'] is Map
          ? Map<String, dynamic>.from(json['requester'])
          : null,
      receiver: json['receiver'] is Map
          ? Map<String, dynamic>.from(json['receiver'])
          : null,
    );
  }

  static String _id(dynamic value) => value is Map
      ? (value['_id']?.toString() ?? '')
      : (value?.toString() ?? '');

  Map<String, dynamic> toJson() {
    return {'requester': requesterId, 'receiver': receiverId, 'status': status};
  }
}
