import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/domain/enums/ward_profile_icon.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';
import 'package:pillura_med/presentation/widgets/ward_icon_picker.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';

class AddWard extends ConsumerStatefulWidget {
  const AddWard({super.key});

  @override
  ConsumerState<AddWard> createState() => _AddWardState();
}

class _AddWardState extends ConsumerState<AddWard> {
  String? _name;
  WardProfileIcon _selectedIcon = WardProfileIcon.person;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подопечный'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              WardIconPicker(
                selectedIcon: _selectedIcon,
                onSelected: (icon) => setState(() => _selectedIcon = icon),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: InputBlock(
                  title: 'Имя',
                  hintText: 'Введите имя',
                  maxLength: kPersonNameMaxLength,
                  validator: validatePersonName,
                  onSaved: (value) {
                    _name = value;
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _addWard,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addWard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSaving = true;
      });

      try {
        await ref.read(authNotifierProvider.notifier).addWard(
              _name!,
              profileIcon: _selectedIcon,
            );
        ref.invalidate(linkedUsersProvider);
        if (!mounted) return;
        AppSnackBar.show(context, 'Подопечный добавлен');
        context.go('/profilePage');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
}
