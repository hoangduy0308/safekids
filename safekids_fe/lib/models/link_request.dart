class LinkRequest {
  final String id;
  final UserInfo sender;
  final UserInfo receiver;
  final String status;
  final String type;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  LinkRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.type,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LinkRequest.fromJson(Map<String, dynamic> json) {
    return LinkRequest(
      id: json['_id'] ?? '',
      sender: UserInfo.fromJson(json['sender']),
      receiver: UserInfo.fromJson(json['receiver']),
      status: json['status'] ?? 'pending',
      type: json['type'] ?? '',
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isParentToChild => type == 'parent_to_child';
  bool get isChildToParent => type == 'child_to_parent';
}

class UserInfo {
  final String id;
  final String fullName;
  final String email;
  final String role;

  UserInfo({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
