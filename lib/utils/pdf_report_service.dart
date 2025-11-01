import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ContractReportRow {
  const ContractReportRow({
    required this.date,
    required this.contractType,
    required this.unitsCompleted,
    required this.ratePerUnit,
    required this.salary,
  });

  final DateTime date;
  final String contractType;
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
    required this.detail,
    required this.salary,
  });

  final String workName;
  final String typeLabel;
  final String detail;
  final double salary;
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
  }) async {
    if (rows.isEmpty) {
      throw ArgumentError('rows must not be empty');
    }

    final document = pw.Document();
    final totalSalary = rows.fold<double>(
      0,
      (previousValue, element) => previousValue + element.salary,
    );

    final tableData = rows
        .map(
          (row) => <String>[
            _formatDate(row.date),
            row.contractType.isEmpty ? '-' : row.contractType,
            row.unitsCompleted.toString(),
            _formatCurrency(currencySymbol, row.ratePerUnit),
            _formatCurrency(currencySymbol, row.salary),
          ],
        )
        .toList(growable: false);

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) => <pw.Widget>[
          _buildHeader(
            title: 'Monthly Contract Report',
            workName: workName,
            periodLabel: monthLabel,
          ),
          pw.SizedBox(height: 20),
          _buildStripedTable(
            headers: const <String>['Date', 'Contract type', 'Units', 'Rate', 'Amount'],
            data: tableData,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellAlignments: const <int, pw.Alignment>{
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#ECFDF5'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('#6EE7B7'), width: 0.6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text(
                  'Total earned',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColor.fromHex('#047857'),
                  ),
                ),
                pw.Text(
                  _formatCurrency(currencySymbol, totalSalary),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColor.fromHex('#065F46'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  }) async {
    if (days.isEmpty) {
      throw ArgumentError('days must not be empty');
    }

    final document = pw.Document();
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
              title: 'Attendance History Report',
              workName: workName,
              periodLabel: monthLabel,
            ),
          ];

          for (final day in days) {
            final dayTotal = day.entries.fold<double>(
              0,
              (previousValue, entry) => previousValue + entry.salary,
            );

            final tableData = day.entries
                .map(
                  (entry) => <String>[
                    entry.typeLabel,
                    entry.workName,
                    entry.detail,
                    _formatCurrency(currencySymbol, entry.salary),
                  ],
                )
                .toList(growable: false);

            widgets
              ..add(pw.SizedBox(height: 18))
              ..add(
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                    borderRadius: pw.BorderRadius.circular(10),
                    color: PdfColors.white,
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        _formatDate(day.date),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildStripedTable(
                        headers: const <String>['Type', 'Work', 'Details', 'Amount'],
                        data: tableData,
                        headerStyle: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
                        cellAlignments: const <int, pw.Alignment>{
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.centerLeft,
                          3: pw.Alignment.centerRight,
                        },
                      ),
                      pw.SizedBox(height: 8),
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'Day total: ${_formatCurrency(currencySymbol, dayTotal)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColor.fromHex('#4338CA'),
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(currencySymbol, totalSalary),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
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
    required String title,
    required String workName,
    required String periodLabel,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Work: $workName',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey600),
        ),
        pw.Text(
          'Period: $periodLabel',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey600),
        ),
      ],
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
      final externalDir = await getExternalStorageDirectory();
      baseDirectory = externalDir ?? await getApplicationDocumentsDirectory();
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

  static String _formatCurrency(String symbol, double amount) {
    final resolvedSymbol = symbol.trim().isEmpty ? '€' : symbol.trim();
    return '$resolvedSymbol${amount.toStringAsFixed(2)}';
  }

  static String _sanitizeFileSegment(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return sanitized.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
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
}
