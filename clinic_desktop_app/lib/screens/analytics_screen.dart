import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Symptom Analytics',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.totalVisits} total visits this month',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Month Picker
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: AppTheme.glassCard(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => provider.previousMonth(),
                      icon: const Icon(Icons.chevron_left_rounded),
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(
                        DateTime(provider.selectedYear, provider.selectedMonth),
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => provider.nextMonth(),
                      icon: const Icon(Icons.chevron_right_rounded),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildChart(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, AnalyticsProvider provider) {
    final entries = provider.symptomCounts.entries.toList();
    final maxY = entries
        .fold<int>(0, (max, e) => e.value > max ? e.value : max)
        .toDouble();

    if (maxY == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No visit data for this month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Record patient visits to see analytics here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Color gradient for bars
    final colors = List.generate(
      entries.length,
      (i) => HSLColor.fromAHSL(
        1,
        (160 + (i * 7.5)) % 360, // Hue rotation starting from teal
        0.65,
        0.55,
      ).toColor(),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + (maxY * 0.2).ceilToDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${entries[group.x.toInt()].key}\n',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} cases',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        // Show abbreviated label
                        final label = entries[idx].key;
                        final abbreviated = label.length > 6
                            ? '${label.substring(0, 5)}.'
                            : label;
                        return SideTitleWidget(
                          meta: meta,
                          angle: -0.8,
                          child: Text(
                            abbreviated,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value.toDouble(),
                        gradient: LinearGradient(
                          colors: [colors[i], colors[i].withValues(alpha: 0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
