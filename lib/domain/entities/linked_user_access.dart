import 'auth_user.dart';
import 'user_link.dart';

class LinkedUserAccess {
  final AuthUser user;
  final UserLinkPermission permission;
  final UserLinkType linkType;

  const LinkedUserAccess({
    required this.user,
    required this.permission,
    required this.linkType,
  });

  bool get canEdit => permission == UserLinkPermission.editor;
}
