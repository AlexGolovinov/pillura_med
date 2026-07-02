import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/entities/linked_user_access.dart';
import '../../../domain/entities/share_invite.dart';
import '../../../domain/entities/user_link.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_provider.dart';

class ShareMedicationsPage extends ConsumerStatefulWidget {
  const ShareMedicationsPage({super.key, this.initialUserId});

  final String? initialUserId;

  @override
  ConsumerState<ShareMedicationsPage> createState() =>
      _ShareMedicationsPageState();
}

class _ShareMedicationsPageState extends ConsumerState<ShareMedicationsPage> {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  final Map<String, ShareInvite> _invitesByProfileId = {};
  bool _isGenerating = false;
  bool _initialized = false;
  String? _selectedProfileId;
  String? _errorText;
  bool _allowEdit = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkedUsers = ref.watch(linkedUsersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final authUser = ref.watch(authNotifierProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: SafeArea(
        child: linkedUsers.when(
          data: (users) {
            final isRestricted =
                authUser?.isAnonymous == true || authUser?.isWard == true;
            if (isRestricted) {
              return const Center(
                child: Text('Для этого аккаунта функция поделиться недоступна'),
              );
            }

            final profiles = _buildShareableProfiles(currentUserId, users);
            if (profiles.isEmpty) {
              return const Center(
                child: Text('Нет профилей, которыми можно поделиться'),
              );
            }

            _initSelectionOnce(profiles);

            final selectedProfile = profiles.firstWhere(
              (profile) => profile.userId == _selectedProfileId,
              orElse: () => profiles.first,
            );
            final selectedInvite = _invitesByProfileId[selectedProfile.userId];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Поделиться \nлекарствами',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 104,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: profiles.length,
                      onPageChanged: (index) => _selectProfile(profiles[index]),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final isSelected = profile.userId == _selectedProfileId;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDE8FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF202D85)
                                  : const Color(0xFFD8D8D8),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile.subtitle,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF666666)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isGenerating)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (selectedInvite != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: selectedInvite.code,
                          version: QrVersions.auto,
                          size: 160,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Поделитесь кодом, и другой человек\nувидит ваш список лекарств.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF707070), fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'или',
                        style: TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8CA1E8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedInvite.code,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF202D85),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _copyCode(selectedInvite.code),
                              icon: const Icon(Icons.copy_rounded),
                              tooltip: 'Скопировать код',
                            ),
                            IconButton(
                              onPressed: _selectedProfileId == null
                                  ? null
                                  : () => _generateInvite(_selectedProfileId!),
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Новый код',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Скажите уникальный код',
                        style: TextStyle(color: Color(0xFF707070), fontSize: 22),
                      ),
                    ],
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _allowEdit,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: _selectedProfileId == null
                          ? null
                          : (value) async {
                              setState(() {
                                _allowEdit = value ?? false;
                              });
                              await _generateInvite(_selectedProfileId!);
                            },
                      title: const Text('Разрешить редактировать список лекарств'),
                    ),
                    const Spacer(),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Ошибка загрузки профилей: $error')),
        ),
      ),
    );
  }

  List<_ShareableProfile> _buildShareableProfiles(
    String? currentUserId,
    List<LinkedUserAccess> users,
  ) {
    if (currentUserId == null) {
      return const [];
    }

    final ids = <String>{};
    final result = <_ShareableProfile>[
      _ShareableProfile(
        userId: currentUserId,
        name: 'Мой профиль',
        subtitle: 'Ваш список лекарств',
      ),
    ];
    ids.add(currentUserId);

    for (final linked in users) {
      final canShareThisLinkedProfile =
          linked.linkType == UserLinkType.ward && linked.canEdit;
      if (!canShareThisLinkedProfile || ids.contains(linked.user.uid)) {
        continue;
      }
      final userName = linked.displayTitle;
      result.add(
        _ShareableProfile(
          userId: linked.user.uid,
          name: userName.isEmpty ? 'Подопечный' : userName,
          subtitle: 'Подопечный',
        ),
      );
      ids.add(linked.user.uid);
    }

    return result;
  }

  void _initSelectionOnce(List<_ShareableProfile> profiles) {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final selectedIndex = profiles.indexWhere(
      (profile) => profile.userId == widget.initialUserId,
    );
    final initial = selectedIndex == -1 ? profiles.first : profiles[selectedIndex];
    _selectedProfileId = initial.userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectedIndex > 0) {
        _pageController.jumpToPage(selectedIndex);
      }
      _generateInvite(initial.userId);
      setState(() {});
    });
  }

  void _selectProfile(_ShareableProfile profile) {
    if (profile.userId == _selectedProfileId) {
      return;
    }

    final cachedInvite = _invitesByProfileId[profile.userId];
    setState(() {
      _selectedProfileId = profile.userId;
      _allowEdit = cachedInvite?.canEdit ?? false;
    });

    if (cachedInvite == null) {
      _generateInvite(profile.userId);
    }
  }

  Future<void> _generateInvite(String profileUserId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Пользователь не авторизован';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorText = null;
    });

    final result = await ref
        .read(authFRepositoryProvider)
        .regenerateShareInvite(
          profileUserId: profileUserId,
          generatedByUserId: currentUserId,
          canEdit: _allowEdit,
        );

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() {
          _errorText = error.toString();
          _isGenerating = false;
        });
      },
      (invite) {
        setState(() {
          _invitesByProfileId[profileUserId] = invite;
          _allowEdit = invite.canEdit;
          _isGenerating = false;
        });
      },
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.show(context, 'Код скопирован');
  }
}

class _ShareableProfile {
  final String userId;
  final String name;
  final String subtitle;

  const _ShareableProfile({
    required this.userId,
    required this.name,
    required this.subtitle,
  });
}
