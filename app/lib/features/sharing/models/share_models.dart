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
  final List<String> previousNames;

  ShareParticipantModel({
    required this.deviceId,
    required this.refereeName,
    required this.role,
    required this.joinedAt,
    this.previousNames = const [],
  });

  factory ShareParticipantModel.fromJson(Map<String, dynamic> json) {
    final rawPrevious = json['previousNames'];
    final prevNames = rawPrevious is List
        ? rawPrevious.where((e) => e != null).map((e) => e.toString()).toList()
        : const <String>[];
    return ShareParticipantModel(
      deviceId: json['deviceId']?.toString() ?? '',
      refereeName: json['refereeName']?.toString() ?? 'Referee',
      role: ShareRole.fromString(json['role']?.toString()),
      joinedAt: (json['joinedAt'] is num)
          ? (json['joinedAt'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
      previousNames: prevNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'refereeName': refereeName,
    'role': role.name,
    'joinedAt': joinedAt,
    'previousNames': previousNames,
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
    final rawParticipants = json['participants'];
    final participantsList = rawParticipants is List
        ? rawParticipants
            .whereType<Map>()
            .map((p) => ShareParticipantModel.fromJson(Map<String, dynamic>.from(p)))
            .toList()
        : <ShareParticipantModel>[];

    return ShareSessionModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      adminDeviceId: json['adminDeviceId']?.toString() ?? '',
      adminRefereeName: json['adminRefereeName']?.toString() ?? 'Head Referee',
      createdAt: (json['createdAt'] is num) ? (json['createdAt'] as num).toInt() : 0,
      updatedAt: (json['updatedAt'] is num) ? (json['updatedAt'] as num).toInt() : 0,
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
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      adminRefereeName: json['adminRefereeName']?.toString() ?? 'Head Referee',
      participantCount: (json['participantCount'] is num)
          ? (json['participantCount'] as num).toInt()
          : 1,
      createdAt: (json['createdAt'] is num) ? (json['createdAt'] as num).toInt() : 0,
    );
  }
}
