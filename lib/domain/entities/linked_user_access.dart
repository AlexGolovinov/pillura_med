import 'package:pillura_med/domain/enums/ward_profile_icon.dart';

import 'auth_user.dart';
import 'user_link.dart';

class LinkedUserAccess {
  final String linkId;
  final AuthUser user;
  final UserLinkPermission permission;
  final UserLinkType linkType;
  final String? displayName;
  final WardProfileIcon? profileIcon;

  const LinkedUserAccess({
    required this.linkId,
    required this.user,
    required this.permission,
    required this.linkType,
    this.displayName,
    this.profileIcon,
  });

  bool get canEdit => permission == UserLinkPermission.editor;

  String get displayTitle {
    final custom = displayName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return (user.name ?? '').trim();
  }
}
