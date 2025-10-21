import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';
import '../models/work.dart';

class WorkDetailScreen extends StatelessWidget {
  const WorkDetailScreen({super.key, required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hourlyRateText = _buildHourlyRateText(l);
    final contractItems = _resolveContractItems();
    final summaryStats = _resolveSummaryStats(l);
    final dateLabel = _formatDate(DateTime.now());
    final startTime = work.additionalData['startTime'] as String? ?? '05:00 AM';
    final endTime = work.additionalData['endTime'] as String? ?? '05:00 AM';
    final breakTime = work.additionalData['breakTime'] as String? ?? '12:30 AM';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A0A0A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.changeWorkButton),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkHeaderCard(
                work: work,
                hourlyRateText: hourlyRateText,
              ),
              const SizedBox(height: 24),
              _AttendanceSection(
                dateLabel: dateLabel,
                startTime: startTime,
                endTime: endTime,
                breakTime: breakTime,
              ),
              const SizedBox(height: 24),
              _ContractSummarySection(
                items: contractItems,
              ),
              const SizedBox(height: 24),
              _MonthlySummarySection(
                stats: summaryStats,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildHourlyRateText(AppLocalizations l) {
    if (work.isContract) {
      return l.contractWorkLabel;
    }
    final rate = work.hourlyRate;
    if (rate == null) {
      return l.notAvailableLabel;
    }
    return '${String.fromCharCode(36)}${rate.toStringAsFixed(2)}/hour';
  }

  List<_ContractItem> _resolveContractItems() {
    final rawItems = work.additionalData['contractItems'];
    if (rawItems is List) {
      return rawItems
          .whereType<Map>()
          .map((item) => _ContractItem(
                title: item['title']?.toString() ?? '',
                price: item['price']?.toString() ?? '',
              ))
          .where((item) => item.title.isNotEmpty && item.price.isNotEmpty)
          .toList();
    }
    return const <_ContractItem>[
      _ContractItem(title: 'Ravanello (10 qty)', price: '\$3 / 100 units'),
      _ContractItem(title: 'Ravanello (10 qty)', price: '\$4 / 100 units'),
      _ContractItem(title: 'Carrot', price: '\$5 / crate'),
    ];
  }

  List<_SummaryStat> _resolveSummaryStats(AppLocalizations l) {
    final summary = work.additionalData['summary'];
    if (summary is Map) {
      final totalHours = summary['totalHours']?.toString();
      final totalSalary = summary['totalSalary']?.toString();
      final hourlyWork = summary['hourlyWork']?.toString();
      final contractWork = summary['contractWork']?.toString();
      return <_SummaryStat>[
        _SummaryStat(
          title: l.totalHoursLabel,
          value: totalHours ?? '0h',
          color: const Color(0xFF2563EB),
        ),
        _SummaryStat(
          title: l.totalSalaryLabel,
          value: totalSalary ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
        ),
        _SummaryStat(
          title: l.hourlyWorkLabel,
          value: hourlyWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF2563EB),
        ),
        _SummaryStat(
          title: l.contractWorkLabel,
          value: contractWork ?? '${String.fromCharCode(36)}0',
          color: const Color(0xFF22C55E),
        ),
      ];
    }

    return <_SummaryStat>[
      _SummaryStat(
        title: l.totalHoursLabel,
        value: '156.5h',
        color: const Color(0xFF2563EB),
      ),
      _SummaryStat(
        title: l.totalSalaryLabel,
        value: '\$1950',
        color: const Color(0xFF22C55E),
      ),
      _SummaryStat(
        title: l.hourlyWorkLabel,
        value: '\$956',
        color: const Color(0xFF2563EB),
      ),
      _SummaryStat(
        title: l.contractWorkLabel,
        value: '\$994',
        color: const Color(0xFF22C55E),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }
}

class _WorkHeaderCard extends StatelessWidget {
  const _WorkHeaderCard({
    required this.work,
    required this.hourlyRateText,
  });

  final Work work;
  final String hourlyRateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hourlyRateText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  work.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Restaurant Job',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 110,
            width: 110,
            child: Image.asset(AppAssets.homeBanner, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.breakTime,
  });

  final String dateLabel;
  final String startTime;
  final String endTime;
  final String breakTime;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.todaysAttendanceTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth < 420
                  ? 1
                  : maxWidth < 720
                      ? 2
                      : 3;
              final itemWidth = crossAxisCount == 1
                  ? maxWidth
                  : (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

              final cards = <Widget>[
                _AttendanceTimeCard(
                  label: l.startTimeLabel,
                  value: startTime,
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF22C55E),
                ),
                _AttendanceTimeCard(
                  label: l.endTimeLabel,
                  value: endTime,
                  icon: Icons.stop_rounded,
                  color: const Color(0xFFEF4444),
                ),
                _AttendanceTimeCard(
                  label: l.breakLabel,
                  value: breakTime,
                  icon: Icons.local_cafe_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ]
                  .map((card) => SizedBox(
                        width: itemWidth.clamp(0.0, maxWidth),
                        child: card,
                      ))
                  .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: Text(l.contractWorkLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: Text(l.submitButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {},
            child: Text(l.markAsWorkOffButton),
          ),
        ],
      ),
    );
  }
}

class _ContractSummarySection extends StatefulWidget {
  const _ContractSummarySection({
    required this.items,
  });

  final List<_ContractItem> items;

  @override
  State<_ContractSummarySection> createState() => _ContractSummarySectionState();
}

class _ContractSummarySectionState extends State<_ContractSummarySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = widget.items;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.contractWorkSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                  ),
                  Text(
                    l.summaryLabel,
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, i == 0 ? 0 : 12, 24,
                        i == items.length - 1 ? 24 : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Text(
                          items[i].price,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthlySummarySection extends StatelessWidget {
  const _MonthlySummarySection({
    required this.stats,
  });

  final List<_SummaryStat> stats;

  @override
  Widget build(BuildContext context) {
    final monthName = _formatMonthYear(DateTime.now());
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$monthName ${l.summaryLabel}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isCompact = maxWidth < 420;
              final crossAxisCount = isCompact ? 1 : 2;
              final childAspectRatio = isCompact ? 3.2 : 2.4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children:
                    stats.map((stat) => _SummaryStatCard(stat: stat)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }
}

class _AttendanceTimeCard extends StatelessWidget {
  const _AttendanceTimeCard({
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
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.stat});

  final _SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.title,
            style: TextStyle(
              color: stat.color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractItem {
  const _ContractItem({required this.title, required this.price});

  final String title;
  final String price;
}

class _SummaryStat {
  const _SummaryStat({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;
}
