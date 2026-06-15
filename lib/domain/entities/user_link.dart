import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pillura_med/domain/enums/ward_profile_icon.dart';

enum UserLinkPermission { viewer, editor }

enum UserLinkStatus { active, revoked }

enum UserLinkType { share, ward }

class UserLink {
  final String id;
  final String outUserId;
  final String inUserId;
  final UserLinkPermission permission;
  final UserLinkStatus status;
  final UserLinkType type;
  final DateTime? createdAt;
  final String? displayName;
  final WardProfileIcon? profileIcon;

  const UserLink({
    required this.id,
    required this.outUserId,
    required this.inUserId,
    required this.permission,
    required this.status,
    required this.type,
    this.createdAt,
    this.displayName,
    this.profileIcon,
  });

  bool get canEdit => permission == UserLinkPermission.editor;

  factory UserLink.fromJson(String id, Map<String, dynamic> json) {
    return UserLink(
      id: id,
      outUserId: json['outUserId'] as String,
      inUserId: json['inUserId'] as String,
      permission: UserLinkPermission.values.firstWhere(
        (e) => e.name == (json['permission'] as String? ?? 'viewer'),
        orElse: () => UserLinkPermission.viewer,
      ),
      status: UserLinkStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'active'),
        orElse: () => UserLinkStatus.active,
      ),
      type: UserLinkType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'share'),
        orElse: () => UserLinkType.share,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      displayName: json['displayName'] as String?,
      profileIcon: json['profileIcon'] == null
          ? null
          : WardProfileIconX.fromStorage(json['profileIcon'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outUserId': outUserId,
      'inUserId': inUserId,
      'permission': permission.name,
      'status': status.name,
      'type': type.name,
      'createdAt': createdAt,
    };
  }
}
