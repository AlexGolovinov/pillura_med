import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';

enum _ScanState { idle, scanning, scanFailed }

class AddByCodePage extends ConsumerStatefulWidget {
  const AddByCodePage({super.key});

  @override
  ConsumerState<AddByCodePage> createState() => _AddByCodePageState();
}

class _AddByCodePageState extends ConsumerState<AddByCodePage> {
  static const Duration _scanTimeout = Duration(seconds: 5);
  static const double _scanBoxSize = 240;

  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );

  _ScanState _scanState = _ScanState.idle;
  bool _isSubmitting = false;
  bool _isScannerActive = false;
  bool _isScannerTransitioning = false;
  Timer? _scanTimer;

  @override
  void dispose() {
    _scanTimer?.cancel();
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isScanning = _scanState == _ScanState.scanning;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Добавить по коду')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                'Сканируйте QR-код приглашения',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isSubmitting ? null : _startScan,
                child: Container(
                  width: _scanBoxSize,
                  height: _scanBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF202D85),
                      width: 2,
                    ),
                    color: const Color(0xFFF4F6FF),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        ),
                        if (!isScanning) _buildScanPlaceholder(theme),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isScanning)
                const Text(
                  'Идет сканирование... до 5 секунд',
                  style: TextStyle(color: Color(0xFF555555)),
                )
              else
                Text(
                  _scanState == _ScanState.scanFailed
                      ? 'Не удалось отсканировать код'
                      : 'Нажмите на квадрат для сканирования',
                  style: TextStyle(
                    color: _scanState == _ScanState.scanFailed
                        ? Colors.red
                        : const Color(0xFF555555),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'ИЛИ',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF8B8B8B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]'))],
                decoration: const InputDecoration(
                  hintText: 'Введите код (пример: ABC-12345)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : () => _submitCode(_codeController.text),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Подтвердить код'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanPlaceholder(ThemeData theme) {
    return Container(
      color: const Color(0xFFF4F6FF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: Color(0xFF202D85),
            ),
            const SizedBox(height: 8),
            Text(
              'Сканировать QR-код',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF202D85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    if (_scanState == _ScanState.scanning ||
        _isSubmitting ||
        _isScannerTransitioning) {
      return;
    }

    setState(() {
      _scanState = _ScanState.scanning;
    });

    final started = await _startScannerSafely();
    if (!started) {
      if (!mounted) return;
      setState(() {
        _scanState = _ScanState.scanFailed;
      });
      AppSnackBar.show(context, 'Не удалось запустить камеру');
      return;
    }

    _scanTimer?.cancel();
    _scanTimer = Timer(_scanTimeout, _onScanTimeout);
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _scanState != _ScanState.scanning || _isSubmitting) {
      return;
    }

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) {
      return;
    }

    _submitCode(rawValue);
  }

  Future<void> _onScanTimeout() async {
    if (!mounted || _scanState != _ScanState.scanning || _isSubmitting) {
      return;
    }

    await _stopScanner();
    if (!mounted) return;
    setState(() {
      _scanState = _ScanState.scanFailed;
    });
    AppSnackBar.show(context, 'Не удалось отсканировать код');
  }

  Future<void> _submitCode(String rawCode) async {
    final normalizedCode = rawCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      AppSnackBar.show(context, 'Введите код');
      return;
    }

    await _stopScanner();
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _scanState = _ScanState.idle;
    });

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || currentUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppSnackBar.show(context, 'Пользователь не авторизован');
      return;
    }

    final result = await ref.read(authFRepositoryProvider).acceptShareInviteCode(
          code: normalizedCode,
          currentUserId: currentUserId,
        );

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() {
          _isSubmitting = false;
        });
        AppSnackBar.show(context, _errorToMessage(error));
      },
      (_) {
        setState(() {
          _isSubmitting = false;
        });
        ref.invalidate(linkedUsersProvider);
        AppSnackBar.show(context, 'Профиль успешно добавлен');
        context.go('/profilePage');
      },
    );
  }

  Future<void> _stopScanner() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (_isScannerTransitioning || !_isScannerActive) {
      return;
    }

    _isScannerTransitioning = true;
    try {
      await _scannerController.stop();
    } on PlatformException catch (e) {
      // Плагин может вернуть эту ошибку при гонке start/stop.
      if (!(e.message?.contains('No active stream to cancel') ?? false)) {
        rethrow;
      }
    } finally {
      _isScannerActive = false;
      _isScannerTransitioning = false;
    }
  }

  Future<bool> _startScannerSafely() async {
    if (_isScannerActive || _isScannerTransitioning) {
      return _isScannerActive;
    }

    _isScannerTransitioning = true;
    try {
      await _scannerController.start();
      _isScannerActive = true;
      return true;
    } catch (_) {
      _isScannerActive = false;
      return false;
    } finally {
      _isScannerTransitioning = false;
    }
  }

  String _errorToMessage(dynamic error) {
    if (error is Exception) {
      final text = error.toString();
      if (text.startsWith('Exception: ')) {
        return text.substring('Exception: '.length);
      }
      return text;
    }
    return error.toString();
  }
}
