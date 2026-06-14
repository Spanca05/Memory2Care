import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/widgets/app_scaffold.dart';

enum _Period { week, month, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Period _period = _Period.week;
  String? _selectedMedId;

  ({DateTime start, DateTime end}) get _range {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return switch (_period) {
      _Period.week => (
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _Period.month => (
        start: DateTime(today.year, today.month, 1),
        end: today,
      ),
      _Period.all => (start: _earliestMedDate(today), end: today),
    };
  }

  DateTime _earliestMedDate(DateTime fallback) {
    final meds = widget.controller.medications;
    if (meds.isEmpty) return fallback.subtract(const Duration(days: 30));
    return meds
        .map(
          (m) => DateTime(m.startDate.year, m.startDate.month, m.startDate.day),
        )
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.controller.medications;
    final range = _range;
    final data = widget.controller.getAdherenceByDay(
      range.start,
      range.end,
      medicationId: _selectedMedId,
    );
    final rate = widget.controller.getAdherenceRate(
      range.start,
      range.end,
      medicationId: _selectedMedId,
    );
    final streak = widget.controller.getCurrentStreak(
      medicationId: _selectedMedId,
    );
    final completed = data.where((d) => d.due > 0 && d.taken == d.due).length;
    final missed = data.where((d) => d.due > 0 && d.taken < d.due).length;

    return AppScaffold(
      title: 'Statistics',
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _PeriodFilter(
            selected: _period,
            onChanged: (p) => setState(() {
              _period = p;
              _selectedMedId = null;
            }),
          ),
          if (meds.length > 1) ...[
            const SizedBox(height: 12),
            _MedicationDropdown(
              medications: meds,
              selectedId: _selectedMedId,
              onChanged: (id) => setState(() => _selectedMedId = id),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Adherence',
                  value: '${rate.toStringAsFixed(0)}%',
                  icon: Icons.track_changes_outlined,
                  color: const Color(0xFF5D9CEC),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Streak',
                  value: '${streak}d',
                  icon: Icons.local_fire_department_outlined,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Done',
                  value: '$completed',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Missed',
                  value: '$missed',
                  icon: Icons.highlight_off_outlined,
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AdherenceChart(data: data, period: _period),
          const SizedBox(height: 20),
          if (meds.isNotEmpty) _MedicationLegend(medications: meds),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChanged});

  final _Period selected;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children:
            _Period.values
                .map(
                  (p) => Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected == p
                                  ? const Color(0xFF5D9CEC)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          switch (p) {
                            _Period.week => 'Week',
                            _Period.month => 'Month',
                            _Period.all => 'All time',
                          },
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color:
                                selected == p ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _MedicationDropdown extends StatelessWidget {
  const _MedicationDropdown({
    required this.medications,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Medication> medications;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String?>(
        value: selectedId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5D9CEC)),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All medications'),
          ),
          ...medications.map(
            (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _AdherenceChart extends StatelessWidget {
  const _AdherenceChart({required this.data, required this.period});

  final List<({DateTime date, int due, int taken})> data;
  final _Period period;

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();
    final hasData = groups.any((g) => g.due > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (period) {
              _Period.week => 'Last 7 days',
              _Period.month => 'This month',
              _Period.all => 'All time',
            },
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adherence per day (%)',
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.black12),
                    SizedBox(height: 8),
                    Text(
                      'No medication data for this period.',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  barGroups:
                      groups.asMap().entries.map((e) {
                        final pct =
                            e.value.due > 0
                                ? (e.value.taken / e.value.due * 100).clamp(
                                  0,
                                  100,
                                ).toDouble()
                                : 0.0;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: pct,
                              color:
                                  e.value.due == 0
                                      ? const Color(0xFFE0E0E0)
                                      : pct >= 100
                                      ? const Color(0xFF4CAF50)
                                      : pct > 0
                                      ? const Color(0xFF5D9CEC)
                                      : const Color(0xFFE53935),
                              width: _barWidth(groups.length),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: const Color(0xFFF5F5F5),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= groups.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              groups[idx].label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
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
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 ||
                              value == 25 ||
                              value == 50 ||
                              value == 75 ||
                              value == 100) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black38,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 25,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine:
                        (_) => const FlLine(
                          color: Color(0xFFEEEEEE),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade700,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final g = groups[group.x];
                        return BarTooltipItem(
                          '${g.label}\n${rod.toY.toStringAsFixed(0)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _chartLegend(),
        ],
      ),
    );
  }

  Widget _chartLegend() {
    return Row(
      children: [
        _legendDot(const Color(0xFF4CAF50), '100%'),
        const SizedBox(width: 12),
        _legendDot(const Color(0xFF5D9CEC), 'Partial'),
        const SizedBox(width: 12),
        _legendDot(const Color(0xFFE53935), 'Missed'),
        const SizedBox(width: 12),
        _legendDot(const Color(0xFFE0E0E0), 'No meds'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }

  double _barWidth(int count) {
    if (count <= 7) return 22;
    if (count <= 12) return 16;
    return 10;
  }

  List<({String label, int due, int taken})> _buildGroups() {
    return switch (period) {
      _Period.week => _groupByDay(),
      _Period.month => _groupByWeek(),
      _Period.all => _groupByMonth(),
    };
  }

  List<({String label, int due, int taken})> _groupByDay() {
    return data
        .map(
          (d) => (
            label: DateFormat('E').format(d.date).substring(0, 2),
            due: d.due,
            taken: d.taken,
          ),
        )
        .toList();
  }

  List<({String label, int due, int taken})> _groupByWeek() {
    final groups = <String, ({int due, int taken})>{};
    for (final d in data) {
      final monday = d.date.subtract(Duration(days: d.date.weekday - 1));
      final key = DateFormat('d/M').format(monday);
      final prev = groups[key] ?? (due: 0, taken: 0);
      groups[key] = (due: prev.due + d.due, taken: prev.taken + d.taken);
    }
    return groups.entries
        .map((e) => (label: e.key, due: e.value.due, taken: e.value.taken))
        .toList();
  }

  List<({String label, int due, int taken})> _groupByMonth() {
    final groups = <String, ({int due, int taken})>{};
    for (final d in data) {
      final key = DateFormat('MMM').format(d.date);
      final prev = groups[key] ?? (due: 0, taken: 0);
      groups[key] = (due: prev.due + d.due, taken: prev.taken + d.taken);
    }
    return groups.entries
        .map((e) => (label: e.key, due: e.value.due, taken: e.value.taken))
        .toList();
  }
}

class _MedicationLegend extends StatelessWidget {
  const _MedicationLegend({required this.medications});

  final List<Medication> medications;

  static const _colors = [
    Color(0xFF5D9CEC),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Medications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...medications.asMap().entries.map((e) {
            final color = _colors[e.key % _colors.length];
            final med = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        med.name.isNotEmpty
                            ? med.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${med.dose} · ${med.timesOfDay.map((t) => t.displayLabel).join(", ")}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!med.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
