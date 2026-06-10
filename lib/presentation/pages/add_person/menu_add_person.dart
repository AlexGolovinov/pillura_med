import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/domain/entities/linked_user_access.dart';
import 'package:pillura_med/domain/entities/user_link.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';

/// Экран выбора: добавить по коду / подопечного (вкладка «Добавить»).
class MenuAddPerson extends ConsumerWidget {
  const MenuAddPerson({super.key});

  static const Color _brand = Color(0xFF202D85);
  static const Color _limeCard = Color(0xFFEEF6D8);
  static const Color _borderLight = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authNotifierProvider).value;
    final List<LinkedUserAccess> linkedUsers = ref
        .watch(linkedUsersProvider)
        .maybeWhen(
      data: (users) => users,
      orElse: () => const <LinkedUserAccess>[],
    );
    final hasShareStatus = linkedUsers.any(
      (user) => user.linkType == UserLinkType.share,
    );
    final isGuestMode = authUser?.isAnonymous == true;
    final isWardAccount = authUser?.isWard == true;
    final isRestricted = isGuestMode || isWardAccount || hasShareStatus;

    final restrictedMessage = isGuestMode
        ? 'В гостевом режиме доступны только лекарства (до 3 шт).'
        : 'Для подопечных и пользователей с share-статусом это действие недоступно.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Добавить'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddOptionCard(
                backgroundColor: _limeCard,
                icon: Icons.qr_code_2_rounded,
                iconColor: _brand,
                title: 'Другого человека По коду',
                subtitle:
                    'У меня есть код / qr, которым со мной поделился другой человек',
                onTap: () {
                  if (isRestricted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(restrictedMessage)),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ввод кода или сканирование QR — в разработке',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _AddOptionCard(
                backgroundColor: Colors.white,
                icon: Icons.person_outline_rounded,
                iconColor: _brand,
                title: 'Подопечного',
                subtitle:
                    'Я хочу добавить человека (или питомца) о котором буду заботиться',
                onTap: () {
                  if (isRestricted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(restrictedMessage)),
                    );
                    return;
                  }
                  context.push('/add/ward');
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  const _AddOptionCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MenuAddPerson._borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: MenuAddPerson._brand,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4A4A4A),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
