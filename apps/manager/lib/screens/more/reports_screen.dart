import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailySalesProvider);
    final top = ref.watch(topProductsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Sales', orange: 'reports'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          _ChartCard(
            title: 'Sales — last 7 days',
            child: SizedBox(
              height: 220,
              child: daily.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => const Center(child: Text('—')),
                data: (rows) => _SalesLineChart(rows: rows),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          _ChartCard(
            title: 'Top products — last 30 days',
            child: SizedBox(
              height: 240,
              child: top.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => const Center(child: Text('—')),
                data: (rows) => rows.isEmpty
                    ? Center(
                        child: Text(
                          'No sales in the last 30 days.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : _TopProductsBarChart(rows: rows),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.lg),
          child,
        ],
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart({required this.rows});
  final List<DailyTotal> rows;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < rows.length; i++) {
      spots.add(FlSpot(i.toDouble(), rows[i].cents / 100));
    }
    final maxY = (spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b))
            .clamp(1, double.infinity) *
        1.2;
    final fmt = DateFormat('d/M');
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble(),
        minY: 0,
        maxY: maxY.toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.muted.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    fmt.format(rows[i].date),
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsBarChart extends StatelessWidget {
  const _TopProductsBarChart({required this.rows});
  final List<ProductTotal> rows;

  @override
  Widget build(BuildContext context) {
    final maxY = rows.first.qty.toDouble() * 1.2;
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                final name = rows[i].name;
                final short =
                    name.length <= 7 ? name : '${name.substring(0, 7)}…';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    short,
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: rows[i].qty.toDouble(),
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
