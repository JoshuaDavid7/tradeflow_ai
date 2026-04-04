import 'package:flutter/material.dart';

import '../../data/services/ai_command_service.dart';
import '../providers/ai_assistant_provider.dart';

Future<AiCommandResult?> showAiAssistantOverlay(
  BuildContext context, {
  required AiAssistantController notifier,
}) {
  return Navigator.of(context).push<AiCommandResult>(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          AiAssistantOverlay(notifier: notifier),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    ),
  );
}

class AiAssistantOverlay extends StatefulWidget {
  final AiAssistantController notifier;

  const AiAssistantOverlay({
    super.key,
    required this.notifier,
  });

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isDone = false;
  String _statusText = 'Starting...';
  String? _actionLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startRecording();
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      await widget.notifier.startRecording();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _statusText = 'Listening for a job, expense, payment, or question.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = 'Could not start recording. Tap the mic to retry.';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isDone) {
      widget.notifier.reset();
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = 'Processing what you said...';
      });

      try {
        final result = await widget.notifier
            .stopAndProcess()
            .timeout(const Duration(seconds: 50));

        if (!mounted) {
          return;
        }

        if (result == null) {
          setState(() {
            _isProcessing = false;
            _statusText = 'Could not process audio. Tap the mic to try again.';
          });
          return;
        }

        setState(() {
          _isProcessing = false;
          _isDone = true;
          _statusText = result.response;
          _actionLabel = _actionToLabel(result.action);
        });

        if (result.action != 'answer') {
          Future.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) {
              return;
            }
            widget.notifier.reset();
            Navigator.pop(context, result);
          });
        }
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isProcessing = false;
          _statusText = 'That took too long. Tap the mic to try again.';
        });
      }
      return;
    }

    await _startRecording();
  }

  String _actionToLabel(String action) {
    switch (action) {
      case 'create_invoice':
        return 'Preparing a draft';
      case 'create_expense':
        return 'Opening expense capture';
      case 'record_payment':
        return 'Opening payment flow';
      case 'navigate':
        return 'Navigating';
      case 'update_settings':
        return 'Updating settings';
      case 'create_note':
        return 'Opening note editor';
      default:
        return '';
    }
  }

  String get _headline {
    if (_isProcessing) {
      return 'Working on it';
    }
    if (_isDone) {
      return 'Done';
    }
    if (_isRecording) {
      return 'Listening';
    }
    return 'Voice Assistant';
  }

  String get _hintText {
    if (_isDone) {
      return 'Tap the mic to dismiss';
    }
    if (_isRecording) {
      return 'Tap once when you finish speaking';
    }
    if (_isProcessing) {
      return 'Hold on while I route the action';
    }
    return 'Tap the mic to start';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _isDone
        ? Colors.green
        : _isRecording
            ? colorScheme.error
            : colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () async {
            await widget.notifier.cancel();
            widget.notifier.reset();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _headline,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: const ValueKey('ai_overlay_mode_chip'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _isProcessing
                                ? 'PROCESSING'
                                : _isRecording
                                    ? 'LISTENING'
                                    : _isDone
                                        ? 'READY'
                                        : 'AI ASSISTANT',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedContainer(
                          key: const ValueKey('ai_overlay_orb'),
                          duration: const Duration(milliseconds: 280),
                          width: _isRecording ? 176 : 160,
                          height: _isRecording ? 176 : 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.12),
                                blurRadius: 36,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: GestureDetector(
                              key: const ValueKey('ai_overlay_primary_button'),
                              onTap: _isProcessing ? null : _toggleRecording,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.28),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isProcessing
                                      ? const SizedBox(
                                          width: 42,
                                          height: 42,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3.2,
                                          ),
                                        )
                                      : Icon(
                                          _isDone
                                              ? Icons.check_rounded
                                              : _isRecording
                                                  ? Icons.stop_rounded
                                                  : Icons.mic_rounded,
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          key: const ValueKey('ai_overlay_headline'),
                          _headline,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          key: const ValueKey('ai_overlay_status_text'),
                          _statusText,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: _isDone
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            height: 1.45,
                            fontWeight: _isDone
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (_actionLabel != null &&
                            _actionLabel!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _actionLabel!,
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          key: const ValueKey('ai_overlay_hint_text'),
                          _hintText,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: _isRecording
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (!_isDone && !_isProcessing) ...[
                          const SizedBox(height: 32),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _SuggestionChip('Invoice Sarah for 3 hours'),
                              _SuggestionChip('Spent \$50 at Home Depot'),
                              _SuggestionChip('How much am I owed?'),
                              _SuggestionChip('Create a note for Steven'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;

  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
