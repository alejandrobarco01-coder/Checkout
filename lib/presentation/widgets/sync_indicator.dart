import 'package:flutter/material.dart';
import '../providers/checklist_provider.dart';

/// Indicador de sincronización con Firestore en el AppBar.
/// Muestra: sincronizando / sincronizado / error / nada.
class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  const SyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (status) {
        SyncStatus.syncing => const Tooltip(
            key: ValueKey('syncing'),
            message: 'Sincronizando...',
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ),
        SyncStatus.synced => const Tooltip(
            key: ValueKey('synced'),
            message: 'Sincronizado',
            child: Icon(Icons.cloud_done, color: Colors.greenAccent, size: 22),
          ),
        SyncStatus.error => const Tooltip(
            key: ValueKey('error'),
            message: 'Error de sincronización',
            child: Icon(Icons.cloud_off, color: Colors.redAccent, size: 22),
          ),
        _ => const SizedBox.shrink(key: ValueKey('idle')),
      },
    );
  }
}
