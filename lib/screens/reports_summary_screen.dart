import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';

class ReportsSummaryScreen extends StatelessWidget {
  const ReportsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    const double combinedSalary = 2456;
    const double hoursWorked = 156.5;
    const int unitsCompleted = 500;
    const double hourlySalary = 1966;
    const int workingDays = 23;
    const double averageHours = 6.8;
    const double lastPayout = 1520;
    const double contractSalary = 500;
    const double hourlyBreakdownTotal = 1956;

    const contractItems = <_ContractWorkItem>[
      _ContractWorkItem(
        title: 'Ravanello (10 qty) @ 5\$ / 100 units',
        subtitle: '100 units completed',
        amount: '\$500',
        indicatorColor: Color(0xFF2EBD5F),
      ),
      _ContractWorkItem(
        title: 'Carrots (15 qty) @ 3\$ / 150 units',
        subtitle: '150 units completed',
        amount: '\$300',
        indicatorColor: Color(0xFF1C87FF),
      ),
      _ContractWorkItem(
        title: 'Watermelons (5 qty) @ 8\$ / 80 units',
        subtitle: '80 units completed',
        amount: '\$240',
        indicatorColor: Color(0xFFFFB74D),
      ),
      _ContractWorkItem(
        title: 'Apples (20 qty) @ 4\$ / 120 units',
        subtitle: '70 units pending',
        amount: '\$0',
        indicatorColor: Color(0xFFFF3B30),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.summarize_outlined,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l.reportsSummaryLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF111827),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthSelector(label: l.reportsSummaryMonth),
            const SizedBox(height: 16),
            _CombinedSalaryCard(
              title: l.reportsCombinedSalaryTitle,
              amount: combinedSalary,
              hoursWorked: hoursWorked,
              unitsCompleted: unitsCompleted,
              hoursLabel: l.reportsHoursWorkedSuffix,
              unitsLabel: l.reportsUnitsCompletedSuffix,
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.reportsHourlyWorkSummaryTitle),
            const SizedBox(height: 12),
            _HourlyWorkSummaryCard(
              totalHoursLabel: l.totalHoursLabel,
              totalHours: hoursWorked,
              hourlySalaryLabel: l.hourlySalaryLabel,
              hourlySalary: hourlySalary,
              workingDaysLabel: l.reportsWorkingDaysLabel,
              workingDays: workingDays,
              averageHoursLabel: l.reportsAverageHoursPerDayLabel,
              averageHours: averageHours,
              lastPayoutLabel: l.reportsLastPayoutLabel,
              lastPayout: lastPayout,
            ),
            const SizedBox(height: 24),
            _SectionTitle(text: l.contractWorkSummaryTitle),
            const SizedBox(height: 12),
            _ContractWorkSummaryCard(
              totalUnitsLabel: l.reportsTotalUnitsLabel,
              totalUnits: unitsCompleted,
              salaryLabel: l.reportsContractSalaryLabel,
              salaryAmount: contractSalary,
              items: contractItems,
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              text: '${l.reportsSummaryMonth} ${l.reportsBreakdownSuffix}',
            ),
            const SizedBox(height: 12),
            _MonthlyBreakdownCard(
              hourlyWorkLabel: l.hourlyWorkLabel,
              hourlyTotal: hourlyBreakdownTotal,
              contractWorkLabel: l.contractWorkLabel,
              contractTotal: contractSalary,
              grandTotalLabel: l.reportsGrandTotalLabel,
              grandTotal: combinedSalary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ) ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _CombinedSalaryCard extends StatelessWidget {
  const _CombinedSalaryCard({
    required this.title,
    required this.amount,
    required this.hoursWorked,
    required this.unitsCompleted,
    required this.hoursLabel,
    required this.unitsLabel,
  });

  final String title;
  final double amount;
  final double hoursWorked;
  final int unitsCompleted;
  final String hoursLabel;
  final String unitsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331F2937),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Updated',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                icon: Icons.access_time,
                label:
                    '${hoursWorked.toStringAsFixed(1)} $hoursLabel',
              ),
              _MetricChip(
                icon: Icons.task_alt,
                label: '$unitsCompleted $unitsLabel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyWorkSummaryCard extends StatelessWidget {
  const _HourlyWorkSummaryCard({
    required this.totalHoursLabel,
    required this.totalHours,
    required this.hourlySalaryLabel,
    required this.hourlySalary,
    required this.workingDaysLabel,
    required this.workingDays,
    required this.averageHoursLabel,
    required this.averageHours,
    required this.lastPayoutLabel,
    required this.lastPayout,
  });

  final String totalHoursLabel;
  final double totalHours;
  final String hourlySalaryLabel;
  final double hourlySalary;
  final String workingDaysLabel;
  final int workingDays;
  final String averageHoursLabel;
  final double averageHours;
  final String lastPayoutLabel;
  final double lastPayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValueTile(
                  label: totalHoursLabel,
                  value: '${totalHours.toStringAsFixed(1)} h',
                  icon: Icons.schedule,
                  iconColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryValueTile(
                  label: hourlySalaryLabel,
                  value: '\$${hourlySalary.toStringAsFixed(0)}',
                  icon: Icons.payments,
                  iconColor: const Color(0xFF059669),
                  emphasizeValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryDetailTile(
                  label: workingDaysLabel,
                  value: workingDays.toString(),
                  icon: Icons.calendar_month,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryDetailTile(
                  label: averageHoursLabel,
                  value: '${averageHours.toStringAsFixed(1)} h',
                  icon: Icons.timer,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryDetailTile(
            label: lastPayoutLabel,
            value: '\$${lastPayout.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _SummaryValueTile extends StatelessWidget {
  const _SummaryValueTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF4F7FB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight:
                      emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                  color: emphasizeValue
                      ? const Color(0xFF059669)
                      : const Color(0xFF111827),
                ) ??
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                      emphasizeValue ? FontWeight.w700 : FontWeight.w600,
                  color: emphasizeValue
                      ? const Color(0xFF059669)
                      : const Color(0xFF111827),
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDetailTile extends StatelessWidget {
  const _SummaryDetailTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        fontSize: 16,
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

class _ContractWorkSummaryCard extends StatelessWidget {
  const _ContractWorkSummaryCard({
    required this.totalUnitsLabel,
    required this.totalUnits,
    required this.salaryLabel,
    required this.salaryAmount,
    required this.items,
  });

  final String totalUnitsLabel;
  final int totalUnits;
  final String salaryLabel;
  final double salaryAmount;
  final List<_ContractWorkItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValueTile(
                  label: totalUnitsLabel,
                  value: totalUnits.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryValueTile(
                  label: salaryLabel,
                  value: '\$${salaryAmount.toStringAsFixed(0)}',
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFF059669),
                  emphasizeValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
              child: _ContractWorkTile(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _ContractWorkItem {
  const _ContractWorkItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.indicatorColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color indicatorColor;
}

class _ContractWorkTile extends StatelessWidget {
  const _ContractWorkTile({required this.item});

  final _ContractWorkItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: item.indicatorColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ) ??
                                const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: item.indicatorColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              item.amount,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: item.indicatorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBreakdownCard extends StatelessWidget {
  const _MonthlyBreakdownCard({
    required this.hourlyWorkLabel,
    required this.hourlyTotal,
    required this.contractWorkLabel,
    required this.contractTotal,
    required this.grandTotalLabel,
    required this.grandTotal,
  });

  final String hourlyWorkLabel;
  final double hourlyTotal;
  final String contractWorkLabel;
  final double contractTotal;
  final String grandTotalLabel;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        );

    TextStyle valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: hourlyWorkLabel,
            value: '\$${hourlyTotal.toStringAsFixed(0)}',
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            indicatorColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: contractWorkLabel,
            value: '\$${contractTotal.toStringAsFixed(0)}',
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            indicatorColor: const Color(0xFF059669),
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _BreakdownRow(
            label: grandTotalLabel,
            value: '\$${grandTotal.toStringAsFixed(0)}',
            labelStyle: labelStyle.copyWith(
              color: const Color(0xFF111827),
            ),
            valueStyle: valueStyle.copyWith(
              color: const Color(0xFF059669),
            ),
            indicatorColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.indicatorColor,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: labelStyle),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
