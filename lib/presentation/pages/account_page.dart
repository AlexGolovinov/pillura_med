import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/app_info.dart';
import 'package:pillura_med/core/notification_service.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/course_schedule.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/domain/entities/user_link.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:pillura_med/presentation/widgets/account_profile_dialogs.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_providers.dart';
import '../providers/repository_provider.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  static const _brandColor = Color(0xFF202D85);
  static const _secondaryText = Color(0xFF6E6E6E);

  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  String? _name;
  String? _email;
  String? _password;
  String _passwordInput = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isSigningOut = false;
  bool _isUpdatingProfile = false;

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode nextFocus) => nextFocus.requestFocus();

  void _closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _upgradeGuestAccount() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).upgradeAnonymousAccount(
            _email!.trim(),
            _password!.trim(),
            _name!.trim(),
          );
      if (!mounted) return;
      final authUser = ref.read(authNotifierProvider).value;
      if (authUser != null &&
          authUser.isAuthenticated &&
          !authUser.isAnonymous) {
        _showMessage('Аккаунт сохранён. Ваши данные остались с вами.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/welcomePage');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message) {
    AppSnackBar.show(context, message);
  }

  Future<void> _editDisplayName(String currentName) async {
    final newName = await showEditDisplayNameDialog(
      context: context,
      currentName: currentName,
    );
    if (newName == null || newName == currentName || !mounted) return;

    setState(() => _isUpdatingProfile = true);
    try {
      final error = await ref
          .read(authNotifierProvider.notifier)
          .updateDisplayName(newName);
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }
      _showMessage('Имя обновлено');
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final success = await showChangePasswordDialog(
      context: context,
      onSubmit: ({required currentPassword, required newPassword}) {
        return ref.read(authNotifierProvider.notifier).changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
      },
    );
    if (success && mounted) {
      _showMessage('Пароль изменён');
    }
  }

  Future<void> _openPrivacyPolicy() async {
    if (kPrivacyPolicyUrl.trim().isEmpty) {
      _showMessage('Ссылка на политику пока не настроена');
      return;
    }

    final uri = Uri.tryParse(kPrivacyPolicyUrl);
    if (uri == null) {
      _showMessage('Некорректная ссылка на политику');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      _showMessage('Не удалось открыть ссылку');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    listenErrors(context, ref, authNotifierProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мой аккаунт')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isGuest = user.isAnonymous;
    final isWard = user.isWard;
    final isRegistered = !isGuest;
    final displayName = (user.name ?? '').trim().isNotEmpty
        ? user.name!.trim()
        : (isGuest ? 'Гость' : 'Пользователь');

    final currentUserId = ref.watch(currentUserIdProvider);
    final medicationsAsync = currentUserId == null
        ? const AsyncValue<List<MedicationWithIntakes>>.loading()
        : ref.watch(medicationNotifierProvider(currentUserId));
    final linkedUsersAsync = ref.watch(linkedUsersProvider);
    final firebaseUser = ref.watch(firebaseAuthStateProvider).value;
    final hasPasswordProvider = firebaseUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;

    final medications = medicationsAsync.value ?? const [];
    final now = DateTime.now();
    final totalMedications = medications.length;
    final activeMedications = medications
        .where((item) => isMedicationCourseActive(item.medication, now))
        .length;
    final todayIntakes = medications.fold<int>(
      0,
      (sum, item) =>
          sum + item.todaysIntakes.where((intake) => intake.isTaken == null).length,
    );
    final linkedUsers = linkedUsersAsync.value ?? const [];
    final wardCount =
        linkedUsers.where((link) => link.linkType == UserLinkType.ward).length;
    final sharedCount =
        linkedUsers.where((link) => link.linkType == UserLinkType.share).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой аккаунт'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeaderCard(
                      displayName: displayName,
                      subtitle: isGuest
                          ? 'Гостевой режим'
                          : (user.email ?? 'Без email'),
                      isGuest: isGuest,
                    ),
                    if (isRegistered) ...[
                      const SizedBox(height: 20),
                      _MiniStatsRow(
                        isLoading: medicationsAsync.isLoading ||
                            linkedUsersAsync.isLoading,
                        showLinkedStats: !isWard,
                        totalMedications: totalMedications,
                        activeMedications: activeMedications,
                        todayIntakes: todayIntakes,
                        wardCount: wardCount,
                        sharedCount: sharedCount,
                      ),
                    ],
                    if (isGuest) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8D4A8)),
                        ),
                        child: Text(
                          'Сейчас вы вошли как гость. Если зарегистрируетесь, '
                          'этот аккаунт будет сохранён: все лекарства и профили '
                          'останутся у вас и не пропадут при выходе.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF5A5A5A),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InputBlock(
                              title: 'Имя',
                              hintText: 'Как к вам обращаться',
                              maxLength: kPersonNameMaxLength,
                              focusNode: _nameFocusNode,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _focusNext(_emailFocusNode),
                              validator: validatePersonName,
                              onSaved: (value) => _name = value,
                            ),
                            const SizedBox(height: 16),
                            InputBlock(
                              title: 'Email',
                              hintText: 'example@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocusNode,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _focusNext(_passwordFocusNode),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите email';
                                }
                                if (!value.contains('@')) {
                                  return 'Введите корректный email';
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value,
                            ),
                            const SizedBox(height: 16),
                            InputBlock(
                              title: 'Пароль',
                              hintText: 'Придумайте пароль',
                              obscureText: _obscurePassword,
                              focusNode: _passwordFocusNode,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _focusNext(_confirmPasswordFocusNode),
                              onChanged: (value) => _passwordInput = value,
                              onToggleObscure: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите пароль';
                                }
                                if (value.length < 6) {
                                  return 'Минимум 6 символов';
                                }
                                return null;
                              },
                              onSaved: (value) => _password = value,
                            ),
                            const SizedBox(height: 16),
                            InputBlock(
                              title: 'Подтверждение пароля',
                              hintText: 'Повторите пароль',
                              obscureText: _obscureConfirmPassword,
                              focusNode: _confirmPasswordFocusNode,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _closeKeyboard(),
                              onToggleObscure: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Подтвердите пароль';
                                }
                                if (value != _passwordInput) {
                                  return 'Пароли не совпадают';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(55),
                                alignment: Alignment.center,
                              ),
                              onPressed:
                                  _isSubmitting ? null : _upgradeGuestAccount,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Зарегистрироваться и сохранить данные',
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isRegistered && !isWard) ...[
                      const SizedBox(height: 24),
                      _AccountSection(
                        title: 'Данные профиля',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Изменить имя'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            enabled: !_isUpdatingProfile,
                            onTap: _isUpdatingProfile
                                ? null
                                : () => _editDisplayName(displayName),
                          ),
                          if (hasPasswordProvider) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: const Icon(Icons.lock_outline_rounded),
                              title: const Text('Сменить пароль'),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              enabled: !_isUpdatingProfile,
                              onTap: _isUpdatingProfile ? null : _changePassword,
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (isRegistered) ...[
                      const SizedBox(height: 24),
                      _AccountSection(
                        title: 'О приложении',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info_outline_rounded),
                            title: const Text('Версия'),
                            trailing: Text(
                              kAppVersion,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: _secondaryText),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.policy_outlined),
                            title: const Text('Политика конфиденциальности'),
                            trailing: const Icon(Icons.open_in_new_rounded),
                            onTap: _openPrivacyPolicy,
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.notifications_active_outlined),
                            title: const Text('Проверить активные уведомления'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              await NotificationService.checkPendingNotifications();
                              if (!mounted) return;
                              _showMessage('Проверка выполнена. Подробности в логе.');
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: OutlinedButton.icon(
                onPressed: _isSigningOut || _isSubmitting || _isUpdatingProfile
                    ? null
                    : _signOut,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Выйти',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.subtitle,
    required this.isGuest,
  });

  final String displayName;
  final String subtitle;
  final bool isGuest;

  static const _brandColor = Color(0xFF202D85);
  static const _cardBackground = Color(0xFFE8EFFB);
  static const _secondaryText = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              isGuest
                  ? Icons.person_outline_rounded
                  : Icons.account_circle_outlined,
              size: 40,
              color: _brandColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _brandColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _secondaryText,
                ),
          ),
          const SizedBox(height: 10),
          _StatusBadge(isGuest: isGuest),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isGuest ? const Color(0xFFFFF8E8) : const Color(0xFF202D85);
    final foregroundColor =
        isGuest ? const Color(0xFF8A6D2B) : Colors.white;
    final label = isGuest ? 'Гостевой режим' : 'Зарегистрированный';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isGuest
            ? Border.all(color: const Color(0xFFE8D4A8))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MiniStatsRow extends StatelessWidget {
  const _MiniStatsRow({
    required this.isLoading,
    required this.showLinkedStats,
    required this.totalMedications,
    required this.activeMedications,
    required this.todayIntakes,
    required this.wardCount,
    required this.sharedCount,
  });

  final bool isLoading;
  final bool showLinkedStats;
  final int totalMedications;
  final int activeMedications;
  final int todayIntakes;
  final int wardCount;
  final int sharedCount;

  Widget _statRow(List<_MiniStatTile> tiles) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingValue = isLoading ? '—' : null;

    return Column(
      children: [
        _statRow([
          _MiniStatTile(
            value: loadingValue ?? '$totalMedications',
            label: 'всего\nлекарств',
          ),
          _MiniStatTile(
            value: loadingValue ?? '$activeMedications',
            label: 'активных\nлекарств',
          ),
          _MiniStatTile(
            value: loadingValue ?? '$todayIntakes',
            label: 'сегодня\nк приёму',
          ),
        ]),
        if (showLinkedStats) ...[
          const SizedBox(height: 10),
          _statRow([
            _MiniStatTile(
              value: loadingValue ?? '$wardCount',
              label: 'подопечных',
            ),
            _MiniStatTile(
              value: loadingValue ?? '$sharedCount',
              label: 'поделившихся',
            ),
          ]),
        ],
      ],
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFFB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF202D85),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF6E6E6E),
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  static const _secondaryText = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EFFB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}
