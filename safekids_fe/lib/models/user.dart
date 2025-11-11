class User {
  final String id;
  final String name;
  final String? fullName;
  final String email;
  final String? phone;
  final String role; // 'parent' or 'child'
  final int? age;
  final List<String> linkedUsers; // User IDs or populated user objects
  final List<Map<String, dynamic>>
  linkedUsersData; // Populated user objects from backend
  final String? fcmToken;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.age,
    this.linkedUsers = const [],
    this.linkedUsersData = const [],
    this.fcmToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle linkedUsers - can be array of IDs or populated objects
    List<String> linkedUserIds = [];
    List<Map<String, dynamic>> linkedUsersDataList = [];
    final Set<String> processedIds = <String>{};

    void addLinkedUser(dynamic item) {
      if (item is Map<String, dynamic>) {
        final nested = item['user'] ?? item['child'] ?? item['parent'];
        if (nested is Map<String, dynamic>) {
          item = nested;
        }

        final rawId = item['_id'] ?? item['id'];
        final id = rawId == null ? '' : rawId.toString();
        if (id.isEmpty || processedIds.contains(id)) {
          return;
        }

        linkedUsersDataList.add({
          '_id': id,
          'id': id,
          'name': item['name'] ?? item['fullName'] ?? '',
          'fullName': item['fullName'] ?? item['name'] ?? '',
          'email': item['email'] ?? '',
          'role': item['role'] ?? 'child',
          'age': item['age'],
          'avatar': item['avatar'],
        });
        processedIds.add(id);
        linkedUserIds.add(id);
      } else if (item is String) {
        if (!processedIds.contains(item)) {
          linkedUserIds.add(item);
          processedIds.add(item);
        }
      }
    }

    void mergeLinkedList(dynamic source) {
      if (source is List) {
        for (final item in source) {
          addLinkedUser(item);
        }
      }
    }

    mergeLinkedList(json['linkedUsersData']);

    mergeLinkedList(json['linkedUsers']);
    mergeLinkedList(json['linkedChildren']);
    mergeLinkedList(json['linkedParents']);

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      fullName: json['fullName'] ?? json['name'], // Fallback to name
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'child',
      age: json['age'],
      linkedUsers: linkedUserIds,
      linkedUsersData: linkedUsersDataList,
      fcmToken: json['fcmToken'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'age': age,
      'linkedUsers': linkedUsers,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    int? age,
    List<String>? linkedUsers,
    List<Map<String, dynamic>>? linkedUsersData,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      age: age ?? this.age,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      linkedUsersData: linkedUsersData ?? this.linkedUsersData,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isParent => role == 'parent';
  bool get isChild => role == 'child';
}
