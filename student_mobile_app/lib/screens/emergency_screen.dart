import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendEmergency() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.danger),
            SizedBox(width: 12),
            Text('Confirm Emergency'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to the school clinic and EMS. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<EmergencyProvider>();
    await provider.sendEmergencyAlert(
      studentId: user.id,
      studentName: user.studentName,
      studentNumber: user.studentNumber,
      message: _messageController.text.trim(),
    );

    _messageController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency alert sent! Help is on the way.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppTheme.danger.withValues(alpha: 0.05),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // SOS Button
                const SizedBox(height: 20),
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: provider.isSending ? null : _sendEmergency,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.dangerGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.danger.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: provider.isSending
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emergency_rounded,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap for immediate medical support',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Optional Message
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Describe your emergency briefly...',
                    prefixIcon: Icon(Icons.message_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                // Alert History Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Alert History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${provider.alerts.length} alert(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Alert List
                if (provider.alerts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 36,
                          color: AppTheme.accent.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No previous alerts',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.alerts.map((alert) {
                    Color statusColor;
                    IconData statusIcon;
                    switch (alert.status) {
                      case 'acknowledged':
                        statusColor = AppTheme.warning;
                        statusIcon = Icons.visibility_rounded;
                        break;
                      case 'resolved':
                        statusColor = AppTheme.accent;
                        statusIcon = Icons.check_circle_rounded;
                        break;
                      default:
                        statusColor = AppTheme.danger;
                        statusIcon = Icons.notification_important_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: alert.isPending
                              ? AppTheme.danger.withValues(alpha: 0.3)
                              : AppTheme.dividerColor,
                          width: alert.isPending ? 1.5 : 0.5,
                        ),
                        color: alert.isPending
                            ? AppTheme.danger.withValues(alpha: 0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      alert.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'MMM dd, hh:mm a',
                                      ).format(alert.timestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (alert.message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (alert.isPending)
                            IconButton(
                              icon: const Icon(Icons.sim_card_alert, size: 20),
                              color: AppTheme.warning,
                              tooltip: 'Simulate Acknowledge',
                              onPressed: () =>
                                  provider.simulateAcknowledge(alert.id),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
