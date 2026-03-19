import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/services/voice_capture_service.dart';

/// Professional voice recording button with animations
class VoiceRecordingButton extends StatelessWidget {
  final VoiceCaptureProgress progress;
  final VoidCallback onTap;
  final double size;

  const VoiceRecordingButton({
    super.key,
    required this.progress,
    required this.onTap,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = progress.state == VoiceCaptureState.recording;
    final isProcessing = progress.isActive && !isRecording;

    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.mediumImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (isRecording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _buildButtonContent(isRecording, isProcessing),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.3),
          )
          .then()
          .shake(
            hz: 2,
            duration: isRecording ? 1000.ms : 0.ms,
          ),
    );
  }

  Widget _buildButtonContent(bool isRecording, bool isProcessing) {
    if (isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(25),
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
          value: progress.progress,
        ),
      );
    }

    return Icon(
      isRecording ? Icons.stop : Icons.mic,
      color: Colors.white,
      size: size * 0.45,
    );
  }
}

/// Progress indicator for voice processing
class VoiceProcessingIndicator extends StatelessWidget {
  final VoiceCaptureProgress progress;

  const VoiceProcessingIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (!progress.isActive) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),

          // Status message
          Text(
            progress.message ?? _getStateMessage(progress.state),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          // Progress percentage
          const SizedBox(height: 4),
          Text(
            '${(progress.progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms);
  }

  String _getStateMessage(VoiceCaptureState state) {
    switch (state) {
      case VoiceCaptureState.recording:
        return 'Recording...';
      case VoiceCaptureState.processing:
        return 'Processing audio...';
      case VoiceCaptureState.uploading:
        return 'Uploading...';
      case VoiceCaptureState.transcribing:
        return 'Transcribing speech...';
      case VoiceCaptureState.extracting:
        return 'Extracting job details...';
      case VoiceCaptureState.completed:
        return 'Complete!';
      case VoiceCaptureState.error:
        return 'Error occurred';
      default:
        return 'Ready';
    }
  }
}

/// Animated status text
class VoiceStatusText extends StatelessWidget {
  final String text;
  final VoiceCaptureState state;

  const VoiceStatusText({
    super.key,
    required this.text,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
      ),
    )
        .animate(
          onPlay: (controller) =>
              state == VoiceCaptureState.recording ? controller.repeat() : null,
        )
        .fadeIn(duration: 300.ms)
        .then()
        .shimmer(
          duration: 1500.ms,
          color: colorScheme.primary.withValues(alpha: 0.3),
        );
  }
}

/// Pulsing recording indicator
class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms);
  }
}
