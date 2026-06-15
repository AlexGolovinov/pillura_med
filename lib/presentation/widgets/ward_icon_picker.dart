import 'package:flutter/material.dart';
import 'package:pillura_med/core/theme/profile_link_colors.dart';
import 'package:pillura_med/domain/enums/ward_profile_icon.dart';

class WardIconPicker extends StatelessWidget {
  const WardIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  final WardProfileIcon selectedIcon;
  final ValueChanged<WardProfileIcon> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Иконка', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final icon in WardProfileIcon.values) ...[
                _WardIconOption(
                  icon: icon,
                  isSelected: selectedIcon == icon,
                  onTap: () => onSelected(icon),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WardIconOption extends StatelessWidget {
  const _WardIconOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final WardProfileIcon icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? ProfileLinkColors.wardProfileSelectedBg
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ProfileLinkColors.wardBorderSelected
                  : ProfileLinkColors.wardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon.iconData,
            size: 28,
            color: isSelected
                ? ProfileLinkColors.wardBorderSelected
                : ProfileLinkColors.wardIcon,
          ),
        ),
      ),
    );
  }
}
