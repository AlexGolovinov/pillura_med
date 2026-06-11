import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/theme/profile_link_colors.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';

/// Экран выбора: добавить по коду / подопечного (вкладка «Добавить»).
class MenuAddPerson extends ConsumerWidget {
  const MenuAddPerson({super.key});

  static const Color _brand = Color(0xFF202D85);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authNotifierProvider).value;

    final isGuestMode = authUser?.isAnonymous == true;
    final isRestricted = isGuestMode || authUser?.isWard == true;
    final restrictedMessage = isGuestMode
        ? 'Войдите в аккаунт с email, чтобы добавлять или принимать приглашения'
        : 'Это действие сейчас недоступно';

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
                backgroundColor: ProfileLinkColors.shareCardBackground,
                borderColor: ProfileLinkColors.shareBorder,
                icon: Icons.qr_code_2_rounded,
                iconColor: ProfileLinkColors.shareBorder,
                title: 'Другого человека по коду',
                subtitle:
                    'У меня есть код или QR, которым со мной поделился другой человек',
                profileColorHint:
                    'В профиле — зелёная рамка. Передать этот доступ дальше нельзя.',
                onTap: () {
                  if (isRestricted) {
                    AppSnackBar.show(context, restrictedMessage);
                    return;
                  }
                  AppSnackBar.show(
                    context,
                    'Ввод кода или сканирование QR — в разработке',
                  );
                },
              ),
              const SizedBox(height: 16),
              _AddOptionCard(
                backgroundColor: ProfileLinkColors.wardCardBackground,
                borderColor: ProfileLinkColors.wardBorder,
                icon: Icons.person_outline_rounded,
                iconColor: ProfileLinkColors.wardBorder,
                title: 'Подопечного',
                subtitle:
                    'Человек (или питомец), о котором вы будете заботиться сами',
                profileColorHint:
                    'В профиле — оранжевая рамка. Этим списком лекарств можно поделиться.',
                onTap: () {
                  if (isRestricted) {
                    AppSnackBar.show(context, restrictedMessage);
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
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.profileColorHint,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String profileColorHint;
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
            border: Border.all(color: borderColor, width: 1.5),
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
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 3, right: 8),
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            profileColorHint,
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5A5A5A),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
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
