import 'package:flutter/material.dart';

/// Error Overlay Widget for on-device debugging
class ErrorOverlay extends StatelessWidget {
  final Widget child;
  static final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  const ErrorOverlay({required this.child, super.key});

  /// Show an error message
  static void showError(String message) {
    errorNotifier.value = message;
  }

  /// Clear the error message
  static void clearError() {
    errorNotifier.value = null;
  }

  /// Show error with auto-dismiss
  static void showErrorWithAutoDismiss(String message, {Duration duration = const Duration(seconds: 5)}) {
    errorNotifier.value = message;
    Future.delayed(duration, () {
      if (errorNotifier.value == message) {
        errorNotifier.value = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<String?>(
          valueListenable: errorNotifier,
          builder: (context, error, _) {
            if (error == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "DEBUG ERROR: $error",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          onPressed: clearError,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
