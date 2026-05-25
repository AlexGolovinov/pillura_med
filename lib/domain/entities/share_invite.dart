class ShareInvite {
  final String code;
  final String profileUserId;
  final String generatedByUserId;
  final bool canEdit;
  final DateTime? createdAt;

  const ShareInvite({
    required this.code,
    required this.profileUserId,
    required this.generatedByUserId,
    required this.canEdit,
    this.createdAt,
  });
}
