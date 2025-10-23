import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/localization/app_localizations.dart';

class ContractWorkScreen extends StatefulWidget {
  const ContractWorkScreen({super.key});

  @override
  State<ContractWorkScreen> createState() => _ContractWorkScreenState();
}

class _ContractWorkScreenState extends State<ContractWorkScreen> {
  final List<_ContractType> _contractTypes = <_ContractType>[
    _ContractType(
      name: 'Ravanello',
      rate: 0.60,
      unitLabel: 'per bunch',
      isDefault: true,
      lastUpdated: DateTime(2025, 9, 28),
    ),
    _ContractType(
      name: 'Radish',
      rate: 0.55,
      unitLabel: 'per bunch',
      isDefault: true,
      lastUpdated: DateTime(2025, 9, 18),
    ),
    _ContractType(
      name: 'Carrot',
      rate: 0.45,
      unitLabel: 'per crate',
      isDefault: true,
      lastUpdated: DateTime(2025, 8, 30),
    ),
  ];

  final List<_ContractEntry> _recentEntries = <_ContractEntry>[
    _ContractEntry(
      date: DateTime(2025, 10, 21),
      workName: 'Greenhouse Harvest',
      contractName: 'Ravanello',
      unitsCompleted: 180,
      rate: 0.6,
      totalAmount: 108,
    ),
    _ContractEntry(
      date: DateTime(2025, 10, 18),
      workName: 'Packing Line',
      contractName: 'Carrot',
      unitsCompleted: 220,
      rate: 0.45,
      totalAmount: 99,
    ),
    _ContractEntry(
      date: DateTime(2025, 10, 12),
      workName: 'Greenhouse Harvest',
      contractName: 'Radish',
      unitsCompleted: 150,
      rate: 0.55,
      totalAmount: 82.5,
    ),
  ];

  void _showComingSoonSnackBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.helpSupportComingSoon)),
    );
  }

  double get _totalUnits =>
      _recentEntries.fold<double>(0, (sum, entry) => sum + entry.unitsCompleted);

  double get _totalContractSalary =>
      _recentEntries.fold<double>(0, (sum, entry) => sum + entry.totalAmount);

  Future<void> _showContractTypeDialog({
    _ContractType? type,
  }) async {
    final l = AppLocalizations.of(context);
    final nameController = TextEditingController(text: type?.name ?? '');
    final rateController =
        TextEditingController(text: type != null ? type.rate.toStringAsFixed(2) : '');
    final unitController = TextEditingController(text: type?.unitLabel ?? '');
    final isEditing = type != null;
    final isNameEditable = !(type?.isDefault ?? false);

    final result = await showDialog<_ContractType>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  AppAssets.contractWork,
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing
                      ? l.contractWorkEditTypeTitle
                      : l.contractWorkAddTypeTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  readOnly: type?.isDefault ?? false,
                  decoration: InputDecoration(
                    labelText: l.contractWorkNameLabel,
                    hintText: 'Ravanello',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: false),
                  decoration: InputDecoration(
                    labelText: l.contractWorkRateLabel,
                    prefixText: '€ ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: l.contractWorkUnitLabel,
                    hintText: 'per crate',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.contractWorkRatesNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ) ??
                      const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancelButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5856D6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final rate = double.tryParse(rateController.text.trim());
                final unit = unitController.text.trim();

                if (name.isEmpty && isNameEditable) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.contractWorkNameRequiredMessage)),
                  );
                  return;
                }
                if (rate == null || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.contractWorkRateRequiredMessage)),
                  );
                  return;
                }
                final fallbackUnit = l.contractWorkUnitFallback;
                final updated = (type ?? _ContractType(name: name, rate: rate))
                    .copyWith(
                      name: type?.name ?? name,
                      rate: rate,
                      unitLabel: unit.isEmpty ? fallbackUnit : unit,
                      lastUpdated: DateTime.now(),
                    );
                Navigator.of(context).pop(updated);
              },
              child: Text(l.saveButtonLabel),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      final index = _contractTypes.indexWhere((item) => item.name == result.name);
      if (index == -1) {
        _contractTypes.add(result);
      } else {
        _contractTypes[index] = result;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.contractWorkTypeSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final totalTypes = _contractTypes.length;

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
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                AppAssets.contractWork,
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l.contractWorkLabel,
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
            _SummaryHeader(
              title: l.contractWorkActiveRatesTitle,
              totalTypes: totalTypes,
              totalUnits: _totalUnits,
              totalAmount: _totalContractSalary,
              activeTypesLabel: l.contractWorkActiveTypesLabel,
              totalUnitsLabel: l.contractWorkTotalUnitsLabel,
              totalSalaryLabel: l.contractWorkTotalSalaryLabel,
            ),
            const SizedBox(height: 20),
            _SectionTitle(text: l.contractWorkDefaultTypesTitle),
            const SizedBox(height: 12),
            Column(
              children: _contractTypes
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContractTypeTile(
                        type: type,
                        lastUpdatedLabel: l.contractWorkLastUpdatedLabel,
                        onEdit: () => _showContractTypeDialog(type: type),
                        editLabel: l.contractWorkEditRateButton,
                        defaultTag: l.contractWorkDefaultTag,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4C1D95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showContractTypeDialog(),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l.addContractWorkButton),
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(text: l.contractWorkRecentEntriesTitle),
            const SizedBox(height: 12),
            if (_recentEntries.isEmpty)
              _EmptyState(message: l.contractWorkNoEntriesLabel)
            else
              Column(
                children: _recentEntries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ContractEntryTile(
                          entry: entry,
                          contractLabel: l.contractWorkLabel,
                          unitsLabel: l.contractWorkUnitsLabel,
                          rateLabel: l.contractWorkRateLabel,
                          onTap: () => _showComingSoonSnackBar(context),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.title,
    required this.totalTypes,
    required this.totalUnits,
    required this.totalAmount,
    required this.activeTypesLabel,
    required this.totalUnitsLabel,
    required this.totalSalaryLabel,
  });

  final String title;
  final int totalTypes;
  final double totalUnits;
  final double totalAmount;
  final String activeTypesLabel;
  final String totalUnitsLabel;
  final String totalSalaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _SummaryItem(
                label: activeTypesLabel,
                value: totalTypes.toString(),
              ),
              const SizedBox(width: 24),
              _SummaryItem(
                label: totalUnitsLabel,
                value: totalUnits.toStringAsFixed(0),
              ),
              const SizedBox(width: 24),
              _SummaryItem(
                label: totalSalaryLabel,
                value: '€${totalAmount.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
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
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
    );
  }
}

class _ContractTypeTile extends StatelessWidget {
  const _ContractTypeTile({
    required this.type,
    required this.lastUpdatedLabel,
    required this.onEdit,
    required this.editLabel,
    required this.defaultTag,
  });

  final _ContractType type;
  final String lastUpdatedLabel;
  final VoidCallback onEdit;
  final String editLabel;
  final String defaultTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${type.displayRate} · ${type.unitLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4B5563),
                          ) ??
                          const TextStyle(
                            color: Color(0xFF4B5563),
                          ),
                    ),
                  ],
                ),
              ),
              if (type.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FDF4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    defaultTag,
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastUpdatedLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ) ??
                        const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.formattedUpdatedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ) ??
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4C1D95),
                ),
                onPressed: onEdit,
                child: Text(editLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContractEntryTile extends StatelessWidget {
  const _ContractEntryTile({
    required this.entry,
    required this.contractLabel,
    required this.unitsLabel,
    required this.rateLabel,
    required this.onTap,
  });

  final _ContractEntry entry;
  final String contractLabel;
  final String unitsLabel;
  final String rateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.workName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ) ??
                            const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ) ??
                            const TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '€${entry.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(label: contractLabel, value: entry.contractName),
                const SizedBox(width: 8),
                _InfoChip(
                  label: unitsLabel,
                  value: entry.unitsCompleted.toStringAsFixed(0),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: rateLabel,
                  value: '€${entry.rate.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 32,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContractType {
  const _ContractType({
    required this.name,
    required this.rate,
    this.unitLabel = 'per unit',
    this.isDefault = false,
    this.lastUpdated,
  });

  final String name;
  final double rate;
  final String unitLabel;
  final bool isDefault;
  final DateTime? lastUpdated;

  _ContractType copyWith({
    String? name,
    double? rate,
    String? unitLabel,
    DateTime? lastUpdated,
  }) {
    return _ContractType(
      name: name ?? this.name,
      rate: rate ?? this.rate,
      unitLabel: unitLabel ?? this.unitLabel,
      isDefault: isDefault,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get displayRate => '€${rate.toStringAsFixed(2)}';

  String get formattedUpdatedDate {
    final date = lastUpdated;
    if (date == null) {
      return '—';
    }
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
    return '$month ${date.day}, ${date.year}';
  }
}

class _ContractEntry {
  const _ContractEntry({
    required this.date,
    required this.workName,
    required this.contractName,
    required this.unitsCompleted,
    required this.rate,
    required this.totalAmount,
  });

  final DateTime date;
  final String workName;
  final String contractName;
  final double unitsCompleted;
  final double rate;
  final double totalAmount;

  String get formattedDate {
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
    return '$month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}
