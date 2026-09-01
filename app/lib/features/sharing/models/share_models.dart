enum ShareRole {
  admin,
  member;

  static ShareRole fromString(String? role) {
    if (role == 'admin') return ShareRole.admin;
    return ShareRole.member;
  }
}

class ShareParticipantModel {
  final String deviceId;
  final String refereeName;
  final ShareRole role;
  final int joinedAt;

  ShareParticipantModel({
    required this.deviceId,
    required this.refereeName,
    required this.role,
    required this.joinedAt,
  });

  factory ShareParticipantModel.fromJson(Map<String, dynamic> json) {
    return ShareParticipantModel(
      deviceId: json['deviceId'] as String? ?? '',
      refereeName: json['refereeName'] as String? ?? 'Referee',
      role: ShareRole.fromString(json['role'] as String?),
      joinedAt: json['joinedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'refereeName': refereeName,
    'role': role.name,
    'joinedAt': joinedAt,
  };
}

class ShareSessionModel {
  final String id;
  final String sku;
  final String adminDeviceId;
  final String adminRefereeName;
  final int createdAt;
  final int updatedAt;
  final List<ShareParticipantModel> participants;

  ShareSessionModel({
    required this.id,
    required this.sku,
    required this.adminDeviceId,
    required this.adminRefereeName,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
  });

  factory ShareSessionModel.fromJson(Map<String, dynamic> json) {
    final participantsList = (json['participants'] as List<dynamic>?)
            ?.map((p) => ShareParticipantModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return ShareSessionModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      adminDeviceId: json['adminDeviceId'] as String? ?? '',
      adminRefereeName: json['adminRefereeName'] as String? ?? 'Head Referee',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      participants: participantsList,
    );
  }
}

class ActiveShareSummary {
  final String id;
  final String sku;
  final String adminRefereeName;
  final int participantCount;
  final int createdAt;

  ActiveShareSummary({
    required this.id,
    required this.sku,
    required this.adminRefereeName,
    required this.participantCount,
    required this.createdAt,
  });

  factory ActiveShareSummary.fromJson(Map<String, dynamic> json) {
    return ActiveShareSummary(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      adminRefereeName: json['adminRefereeName'] as String? ?? 'Head Referee',
      participantCount: json['participantCount'] as int? ?? 1,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}
