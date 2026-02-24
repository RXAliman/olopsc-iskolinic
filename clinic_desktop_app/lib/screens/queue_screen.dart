import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../theme/app_theme.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, queue, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Queue',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage patient queue and connect the clinic input app',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Connect / QR button
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showQrCode = !_showQrCode),
                    icon: Icon(
                      _showQrCode
                          ? Icons.close_rounded
                          : Icons.qr_code_2_rounded,
                      size: 20,
                    ),
                    label: Text(_showQrCode ? 'Hide QR' : 'Connect App'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // QR Code card (collapsible)
              if (_showQrCode) ...[
                _buildQrCodeCard(),
                const SizedBox(height: 24),
              ],

              // Queue stats
              Row(
                children: [
                  _StatChip(
                    label: 'Waiting',
                    count: queue.waitingCount,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'In Progress',
                    count: queue.inProgressItems.length,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Done',
                    count: queue.doneItems.length,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Queue list
              if (queue.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (queue.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${queue.error}',
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                )
              else if (queue.queueItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients in queue',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Patients will appear here when they join via the clinic input app',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...queue.queueItems.map((item) => _QueueItemTile(item: item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: Row(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: 'clinicinput',
              version: QrVersions.auto,
              size: 160,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan to Connect',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Open the clinic input app and scan this QR code to start sending patients to the queue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Listening for connections...',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Queue Item Tile ──────────────────────────────────────────────
class _QueueItemTile extends StatelessWidget {
  final QueueItem item;

  const _QueueItemTile({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case 'in_progress':
        return AppTheme.accent;
      case 'done':
        return AppTheme.textMuted;
      default:
        return AppTheme.warning;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Done';
      default:
        return 'Waiting';
    }
  }

  IconData get _statusIcon {
    switch (item.status) {
      case 'in_progress':
        return Icons.play_circle_rounded;
      case 'done':
        return Icons.check_circle_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = context.read<QueueProvider>();
    final timeStr = DateFormat('hh:mm a').format(item.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.status == 'done'
            ? AppTheme.cardLight.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.status == 'in_progress'
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: item.status == 'done'
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                    decoration: item.status == 'done'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.studentNumber} · ${item.reason}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),

          // Time
          Text(
            timeStr,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          if (item.status == 'waiting')
            IconButton(
              tooltip: 'Start',
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
              onPressed: () =>
                  queueProvider.updateStatus(item.id, 'in_progress'),
            ),
          if (item.status == 'in_progress')
            IconButton(
              tooltip: 'Mark Done',
              icon: const Icon(
                Icons.check_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
              onPressed: () => queueProvider.updateStatus(item.id, 'done'),
            ),
          IconButton(
            tooltip: 'Remove',
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () => queueProvider.removeFromQueue(item.id),
          ),
        ],
      ),
    );
  }
}
