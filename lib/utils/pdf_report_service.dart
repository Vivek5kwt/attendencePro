import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ContractReportRow {
  const ContractReportRow({
    required this.date,
    required this.contractType,
    required this.unitLabel,
    required this.unitsCompleted,
    required this.ratePerUnit,
    required this.salary,
  });

  final DateTime date;
  final String contractType;
  final String unitLabel;
  final int unitsCompleted;
  final double ratePerUnit;
  final double salary;
}

class HistoryReportDay {
  const HistoryReportDay({
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<HistoryReportEntry> entries;
}

class HistoryReportEntry {
  const HistoryReportEntry({
    required this.workName,
    required this.typeLabel,
    required this.totalHours,
    required this.salary,
    this.contractTypeLabel,
  });

  final String workName;
  final String typeLabel;
  final double totalHours;
  final double salary;
  final String? contractTypeLabel;
}

class HistoryReportSummary {
  const HistoryReportSummary({
    required this.totalHoursWorked,
    required this.totalHourlySalary,
    required this.totalContractSalary,
    required this.grandTotalEarnings,
  });

  final double totalHoursWorked;
  final double totalHourlySalary;
  final double totalContractSalary;
  final double grandTotalEarnings;
}

class PdfReportService {
  const PdfReportService._();

  static const List<String> _monthNames = <String>[
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

  static Future<File> generateMonthlyContractReport({
    required String workName,
    required String monthLabel,
    required String currencySymbol,
    required List<ContractReportRow> rows,
    HistoryReportSummary? summary,
  }) async {
    if (rows.isEmpty) {
      throw ArgumentError('rows must not be empty');
    }

    final fonts = await _resolveFonts();
    final document = pw.Document(theme: fonts.theme);

    final contractTotals = <String, MapEntry<int, double>>{};
    final contractLabels = <String, String>{};
    var totalUnits = 0;
    var totalSalary = 0.0;

    final currencyLabel = _resolveCurrencyLabel(currencySymbol);

    final tableData = rows.map((row) {
      final rawLabel = row.contractType.trim();
      final label = rawLabel.isEmpty ? '-' : rawLabel;
      final normalizedLabel = label.toLowerCase();

      final entry = contractTotals[normalizedLabel];
      final updatedUnits = (entry?.key ?? 0) + row.unitsCompleted;
      final updatedSalary = (entry?.value ?? 0) + row.salary;

      contractTotals[normalizedLabel] = MapEntry(updatedUnits, updatedSalary);
      contractLabels.putIfAbsent(normalizedLabel, () => label);

      totalUnits += row.unitsCompleted;
      totalSalary += row.salary;

      return <String>[
        _formatContractDate(row.date),
        label,
        row.unitsCompleted.toString(),
        _formatContractRate(currencyLabel, row.ratePerUnit, row.unitLabel),
        _formatContractCurrency(currencyLabel, row.salary),
      ];
    }).toList(growable: false);

    final monthlyTotals = <List<String>>[];
    var serial = 1;
    // Preserve the original insertion order so the monthly totals table mirrors
    // the sequence of contract types shown in the daily entries.
    for (final entry in contractTotals.entries) {
      final displayLabel = contractLabels[entry.key] ?? entry.key;
      monthlyTotals.add(<String>[
        '${serial++}.',
        displayLabel,
        entry.value.key.toString(),
        _formatContractCurrency(currencyLabel, entry.value.value),
      ]);
    }

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) {
          final widgets = <pw.Widget>[
            _buildHeader(
              fonts: fonts,
              title: 'Contract Work Summary',
              workName: workName,
              periodLabel: monthLabel,
            ),
            pw.SizedBox(height: 18),
            _buildSectionTitle(fonts: fonts, title: 'Daily Wise Total'),
            pw.SizedBox(height: 10),
            _buildBorderedTable(
              fonts: fonts,
              headers: const <String>['Date', 'Contract Type', 'Unit', 'Rate', 'Salary'],
              data: tableData,
              cellAlignments: const <int, pw.Alignment>{
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 18),
            _buildSectionTitle(fonts: fonts, title: 'Monthly Total'),
            pw.SizedBox(height: 10),
            _buildBorderedTable(
              fonts: fonts,
              headers: const <String>['Sr. no', 'Contract Type', 'Unit', 'Salary'],
              data: monthlyTotals,
              cellAlignments: const <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 16),
            _buildBorderedTable(
              fonts: fonts,
              headers: const <String>['Label', 'Amount'],
              data: <List<String>>[
                <String>['Total Unit', totalUnits.toString()],
                <String>['Net Salary', _formatContractCurrency(currencyLabel, totalSalary)],
              ],
              cellAlignments: const <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.center,
              },
            ),
          ];

          if (summary != null) {
            widgets
              ..add(pw.SizedBox(height: 16))
              ..add(
                _buildHistorySummary(
                  fonts: fonts,
                  currencySymbol: currencySymbol,
                  summary: summary,
                ),
              );
          }

          return widgets;
        },
      ),
    );

    final sanitizedMonth = _sanitizeFileSegment(monthLabel);
    final sanitizedWork = _sanitizeFileSegment(workName);
    final fileName = 'contract_report_${sanitizedWork}_$sanitizedMonth.pdf';

    return _saveDocument(document, fileName);
  }

  static Future<File> generateAttendanceHistoryReport({
    required String workName,
    required String monthLabel,
    required String currencySymbol,
    required List<HistoryReportDay> days,
    HistoryReportSummary? summary,
  }) async {
    if (days.isEmpty) {
      throw ArgumentError('days must not be empty');
    }

    final fonts = await _resolveFonts();
    final document = pw.Document(theme: fonts.theme);
    final totalSalary = days.fold<double>(
      0,
          (previousValue, day) => previousValue +
          day.entries.fold<double>(
            0,
                (dayValue, entry) => dayValue + entry.salary,
          ),
    );

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) {
          final widgets = <pw.Widget>[
            _buildHeader(
              fonts: fonts,
              title: 'Attendance History Report',
              workName: workName,
              periodLabel: monthLabel,
            ),
          ];

          final sortedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
          final tableRows = <List<String>>[];

          for (final day in sortedDays) {
            for (final entry in day.entries) {
              final totalHoursLabel = _formatHours(entry.totalHours);
              final contractName =
                  entry.contractTypeLabel?.trim().isNotEmpty == true
                      ? entry.contractTypeLabel!.trim()
                      : '-';

              tableRows.add(<String>[
                _formatDate(day.date),
                entry.typeLabel,
                entry.workName,
                contractName,
                totalHoursLabel,
                _formatCurrency(currencySymbol, entry.salary),
              ]);
            }
          }

          widgets
            ..add(pw.SizedBox(height: 18))
            ..add(
              _buildSectionTitle(fonts: fonts, title: 'Daily entries'),
            )
            ..add(pw.SizedBox(height: 10))
            ..add(
              _buildStripedTable(
                headers: const <String>[
                  'Date',
                  'Type',
                  'Work',
                  'Contract',
                  'Total Hours',
                  'Amount',
                ],
                data: tableRows,
                headerStyle: _textStyle(
                  fonts,
                  font: fonts.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                cellStyle: _textStyle(fonts, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
                cellAlignments: const <int, pw.Alignment>{
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
              ),
            );

          if (summary != null) {
            widgets
              ..add(pw.SizedBox(height: 20))
              ..add(
                _buildHistorySummary(
                  fonts: fonts,
                  currencySymbol: currencySymbol,
                  summary: summary,
                ),
              );
          }

          widgets
            ..add(pw.SizedBox(height: 20))
            ..add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF2FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor.fromHex('#C7D2FE'), width: 0.6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Text(
                      'Monthly total',
                      style: _textStyle(
                        fonts,
                        font: fonts.bold,
                        fontSize: 12,
                        color: PdfColor.fromHex('#4338CA'),
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(currencySymbol, totalSalary),
                      style: _textStyle(
                        fonts,
                        font: fonts.bold,
                        fontSize: 12,
                        color: PdfColor.fromHex('#312E81'),
                      ),
                    ),
                  ],
                ),
              ),
            );

          return widgets;
        },
      ),
    );

    final sanitizedMonth = _sanitizeFileSegment(monthLabel);
    final sanitizedWork = _sanitizeFileSegment(workName);
    final fileName = 'attendance_history_${sanitizedWork}_$sanitizedMonth.pdf';

    return _saveDocument(document, fileName);
  }

  static pw.Widget _buildHeader({
    required _PdfFontAssets fonts,
    required String title,
    required String workName,
    required String periodLabel,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          title,
          style: _textStyle(
            fonts,
            font: fonts.bold,
            fontSize: 20,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Work: $workName',
          style: _textStyle(
            fonts,
            fontSize: 11,
            color: PdfColors.blueGrey600,
          ),
        ),
        pw.Text(
          'Period: $periodLabel',
          style: _textStyle(
            fonts,
            fontSize: 11,
            color: PdfColors.blueGrey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHistorySummary({
    required _PdfFontAssets fonts,
    required String currencySymbol,
    required HistoryReportSummary summary,
  }) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Total Hours Worked', _formatHours(summary.totalHoursWorked)),
      MapEntry(
        'Total Hourly Salary',
        _formatCurrency(currencySymbol, summary.totalHourlySalary),
      ),
    ];

    if (summary.totalContractSalary > 0) {
      rows.add(
        MapEntry(
          'Total Contract Salary',
          _formatCurrency(currencySymbol, summary.totalContractSalary),
        ),
      );
    }

    rows.add(
      MapEntry(
        'Grand Total Earnings',
        _formatCurrency(currencySymbol, summary.grandTotalEarnings),
      ),
    );

    pw.Widget buildRow(String label, String value, {bool isEmphasis = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Text(
                label,
                style: _textStyle(
                  fonts,
                  font: isEmphasis ? fonts.bold : fonts.regular,
                  fontSize: 11,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
            pw.Text(
              value,
              style: _textStyle(
                fonts,
                font: isEmphasis ? fonts.bold : fonts.regular,
                fontSize: 11,
                color: isEmphasis ? PdfColors.blueGrey900 : PdfColors.blueGrey700,
              ),
            ),
          ],
        ),
      );
    }

    final widgets = <pw.Widget>[
      pw.Text(
        'Summary',
        style: _textStyle(
          fonts,
          font: fonts.bold,
          fontSize: 13,
          color: PdfColors.blueGrey900,
        ),
      ),
      pw.SizedBox(height: 8),
    ];

    for (var i = 0; i < rows.length; i++) {
      final isLast = i == rows.length - 1;
      widgets.add(
        buildRow(
          rows[i].key,
          rows[i].value,
          isEmphasis: isLast,
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F3FF'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#DDD6FE'), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  static Future<File> _saveDocument(pw.Document document, String fileName) async {
    final bytes = await document.save();
    final directory = await _resolveReportDirectory();
    final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<Directory> _resolveReportDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Saving PDF files is not supported on the web');
    }

    Directory baseDirectory;
    if (Platform.isAndroid) {
      // Prefer an internal directory to avoid storage permission issues on
      // newer Android versions. If that fails for any reason, gracefully
      // fall back to the external storage location or, as a last resort, the
      // temporary directory so the download flow does not crash.
      try {
        baseDirectory = await getApplicationDocumentsDirectory();
      } catch (_) {
        baseDirectory = await getExternalStorageDirectory() ??
            await getTemporaryDirectory();
      }
    } else {
      baseDirectory = await getApplicationDocumentsDirectory();
    }

    final reportsDirectoryPath =
        '${baseDirectory.path}${Platform.pathSeparator}reports';
    final reportsDirectory = Directory(reportsDirectoryPath);
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }
    return reportsDirectory;
  }

  static String _formatDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day $month $year';
  }

  static String _formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final clampedMinutes = totalMinutes < 0 ? 0 : totalMinutes;
    final resolvedHours = clampedMinutes ~/ 60;
    final minutes = clampedMinutes % 60;
    if (minutes == 0) {
      return '${resolvedHours}h';
    }
    return '${resolvedHours}h ${minutes}m';
  }

  static String _formatCurrency(String symbol, double amount) {
    final resolvedSymbol = symbol.trim().isEmpty ? '€' : symbol.trim();
    return '$resolvedSymbol${amount.toStringAsFixed(2)}';
  }

  static String _sanitizeFileSegment(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return sanitized.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _resolveCurrencyLabel(String symbol) {
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) return 'Euro';
    if (trimmed == '€') return 'Euro';
    return trimmed;
  }

  static String _formatContractCurrency(String currencyLabel, double amount) {
    return '${_formatNumber(amount)} $currencyLabel';
  }

  static String _formatContractRate(
    String currencyLabel,
    double rate,
    String unitLabel,
  ) {
    final sanitizedUnit = unitLabel.trim().isEmpty ? 'per unit' : unitLabel.trim();
    return '${_formatNumber(rate)} $currencyLabel / $sanitizedUnit';
  }

  static String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    final rounded = value.roundToDouble();
    if (rounded == value) return rounded.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String _formatContractDate(DateTime date) {
    final month = _monthNames[date.month - 1].substring(0, 3).toLowerCase();
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static pw.Widget _buildBorderedTable({
    required _PdfFontAssets fonts,
    required List<String> headers,
    required List<List<String>> data,
    required Map<int, pw.Alignment> cellAlignments,
  }) {
    final headerStyle = _textStyle(fonts, font: fonts.bold, fontSize: 11);
    final cellStyle = _textStyle(fonts, fontSize: 10.5);
    final defaultAlignment = pw.Alignment.centerLeft;

    final rows = <pw.TableRow>[
      pw.TableRow(
        children: List<pw.Widget>.generate(
          headers.length,
          (index) => _buildTableCell(
            text: headers[index],
            style: headerStyle,
            alignment: cellAlignments[index] ?? defaultAlignment,
          ),
        ),
      ),
    ];

    for (final row in data) {
      rows.add(
        pw.TableRow(
          children: List<pw.Widget>.generate(
            headers.length,
            (index) => _buildTableCell(
              text: index < row.length ? row[index] : '',
              style: cellStyle,
              alignment: cellAlignments[index] ?? defaultAlignment,
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  static pw.Widget _buildSectionTitle({
    required _PdfFontAssets fonts,
    required String title,
  }) {
    return pw.Text(
      title,
      style: _textStyle(
        fonts,
        font: fonts.bold,
        fontSize: 12,
        color: PdfColors.black,
      ),
    );
  }

  static pw.Widget _buildStripedTable({
    required List<String> headers,
    required List<List<String>> data,
    required pw.TextStyle headerStyle,
    required pw.TextStyle cellStyle,
    required pw.BoxDecoration headerDecoration,
    required pw.TableBorder border,
    required Map<int, pw.Alignment> cellAlignments,
    PdfColor? evenRowColor,
    PdfColor? oddRowColor,
  }) {
    final resolvedEvenColor = evenRowColor ?? PdfColors.grey100;
    final resolvedOddColor = oddRowColor ?? PdfColors.white;
    final defaultAlignment = pw.Alignment.centerLeft;

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: headerDecoration,
        children: List<pw.Widget>.generate(
          headers.length,
              (index) => _buildTableCell(
            text: headers[index],
            style: headerStyle,
            alignment: cellAlignments[index] ?? defaultAlignment,
          ),
        ),
      ),
    ];

    for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final row = data[rowIndex];
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: rowIndex.isEven ? resolvedEvenColor : resolvedOddColor,
          ),
          children: List<pw.Widget>.generate(
            headers.length,
                (index) => _buildTableCell(
              text: index < row.length ? row[index] : '',
              style: cellStyle,
              alignment: cellAlignments[index] ?? defaultAlignment,
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: border,
      children: rows,
    );
  }

  static pw.Widget _buildTableCell({
    required String text,
    required pw.TextStyle style,
    required pw.Alignment alignment,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: style),
    );
  }

  static Future<_PdfFontAssets> _resolveFonts() async {
    final cached = _cachedFonts;
    if (cached != null) {
      return cached;
    }

    final regular = pw.Font.ttf(await rootBundle.load('fonts/Inter_24pt-Regular.ttf'));
    final medium = pw.Font.ttf(await rootBundle.load('fonts/Inter_24pt-Medium.ttf'));
    final semiBold =
    pw.Font.ttf(await rootBundle.load('fonts/Inter_24pt-SemiBold.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('fonts/Inter_24pt-Bold.ttf'));

    final fonts = _PdfFontAssets(
      regular: regular,
      medium: medium,
      semiBold: semiBold,
      bold: bold,
    );
    _cachedFonts = fonts;
    return fonts;
  }

  static pw.TextStyle _textStyle(
      _PdfFontAssets fonts, {
        double? fontSize,
        PdfColor? color,
        pw.FontWeight? fontWeight,
        pw.Font? font,
      }) {
    return pw.TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      font: font ?? fonts.regular,
      fontFallback: fonts.fallback,
    );
  }

  static _PdfFontAssets? _cachedFonts;
}

class _PdfFontAssets {
  _PdfFontAssets({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
    List<pw.Font> fallbackFonts = const <pw.Font>[],
  })  : fallback = List<pw.Font>.unmodifiable(
    <pw.Font>{
      regular,
      medium,
      semiBold,
      bold,
      ...fallbackFonts,
    }.toList(),
  ),
        theme = pw.ThemeData.withFont(
          base: regular,
          bold: bold,
          italic: regular,
          boldItalic: bold,
        );

  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font bold;
  final List<pw.Font> fallback;
  final pw.ThemeData theme;
}
