import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExportHelper {
  static Future<void> sharePdf({
    required String dateRange,
    required Map<String, String> summary,
    required List<List<String>> incomeRows,
    required List<List<String>> salaryRows,
    required List<List<String>> managerSalaryRows,
    required List<List<String>> expenseRows,
    required List<List<String>> purchaseRows,
    required List<List<String>> organicFertilizerRows,
    required List<List<String>> usageRows,
    required List<List<String>> treeCountRows,
    required List<List<String>> treeCuttingRows,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Estate Reports Dashboard',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('ChinRam Estate, Farm & Dryer Management System', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.Text('Report Period: $dateRange', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text('Generated On: ${DateTime.now().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Overall Financial Summary
          pw.Text('Overall Financial Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#606C38'))),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: summary.entries.map((entry) {
                final isNetProfit = entry.key == 'Net Profit';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(entry.key, style: pw.TextStyle(fontWeight: isNetProfit ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.grey800)),
                      pw.Text(entry.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isNetProfit ? PdfColors.brown800 : PdfColors.grey900)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 24),

          // 1. Estate Income
          if (incomeRows.isNotEmpty) ...[
            pw.Text('1. Estate Income Records', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Category', 'Product', 'Qty', 'Green Qty', 'Dry Qty', 'Percent', 'Rate', 'Total'],
              data: incomeRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 2. Worker Salaries
          if (salaryRows.isNotEmpty) ...[
            pw.Text('2. Worker Salary Logs', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Worker Name', 'Period', 'Wages Paid', 'Status', 'Paid Date'],
              data: salaryRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 3. Other Expenses
          if (expenseRows.isNotEmpty) ...[
            pw.Text('3. Other Expenses Logs', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Category', 'Notes', 'Amount'],
              data: expenseRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 4. Fertilizer Purchases
          if (purchaseRows.isNotEmpty) ...[
            pw.Text('4. Fertilizer Purchase batches', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Fertilizer', 'Qty Purchased', 'Price', 'Total'],
              data: purchaseRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 4.5 Organic Fertilizer Purchases
          if (organicFertilizerRows.isNotEmpty) ...[
            pw.Text('4.5 Organic Fertilizer Purchases', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Organic Fertilizer', 'Loads', 'Unit', 'Price'],
              data: organicFertilizerRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 5. Fertilizer Usages
          if (usageRows.isNotEmpty) ...[
            pw.Text('5. Fertilizer Stock Usages', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Fertilizer', 'Bags Used', 'Remaining Stock'],
              data: usageRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 6. Tree Counts
          if (treeCountRows.isNotEmpty) ...[
            pw.Text('6. Tree Count Records', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date Recorded', 'Tree Name', 'Plot', 'Current Count'],
              data: treeCountRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 7. Tree Cuttings
          if (treeCuttingRows.isNotEmpty) ...[
            pw.Text('7. Tree Cutting Logs (Mara Vettu)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Date Cut', 'Tree Name', 'Place', 'Trees Cut', 'Price/Tree', 'Total Realized'],
              data: treeCuttingRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // 8. Manager Told Salaries
          if (managerSalaryRows.isNotEmpty) ...[
            pw.Text('8. Manager Told Salary Logs', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['From Date', 'To Date', 'Weekly Salary', 'Created Date'],
              data: managerSalaryRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Estate_Dashboard_Report.pdf");
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'ChinRam Reports Dashboard Document');
  }

  static Future<void> shareExcel({
    required String dateRange,
    required Map<String, String> summary,
    required List<List<String>> incomeRows,
    required List<List<String>> salaryRows,
    required List<List<String>> managerSalaryRows,
    required List<List<String>> expenseRows,
    required List<List<String>> purchaseRows,
    required List<List<String>> organicFertilizerRows,
    required List<List<String>> usageRows,
    required List<List<String>> treeCountRows,
    required List<List<String>> treeCuttingRows,
  }) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Add title
    sheet.appendRow([xl.TextCellValue('Estate Reports Dashboard')]);
    sheet.appendRow([xl.TextCellValue('Report Period: $dateRange')]);
    sheet.appendRow([xl.TextCellValue('Generated On: ${DateTime.now().toString().split('.')[0]}')]);
    sheet.appendRow([]); // empty spacing row

    // Financial KPI summaries
    sheet.appendRow([xl.TextCellValue('Financial Summary KPIs')]);
    for (final entry in summary.entries) {
      sheet.appendRow([xl.TextCellValue(entry.key), xl.TextCellValue(entry.value)]);
    }
    sheet.appendRow([]); // spacing

    // 1. Income
    if (incomeRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('1. Estate Income Records')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Product'),
        xl.TextCellValue('Quantity'),
        xl.TextCellValue('Green Qty'),
        xl.TextCellValue('Dry Qty'),
        xl.TextCellValue('Percent'),
        xl.TextCellValue('Rate'),
        xl.TextCellValue('Total Amount'),
      ]);
      for (final r in incomeRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 2. Salary
    if (salaryRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('2. Worker Salary Logs')]);
      sheet.appendRow([
        xl.TextCellValue('Worker Name'),
        xl.TextCellValue('Period'),
        xl.TextCellValue('Wages Paid'),
        xl.TextCellValue('Status'),
        xl.TextCellValue('Paid Date'),
      ]);
      for (final r in salaryRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 3. Other Expenses
    if (expenseRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('3. Other Expenses Logs')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Notes'),
        xl.TextCellValue('Amount'),
      ]);
      for (final r in expenseRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 4. Purchases
    if (purchaseRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('4. Fertilizer Purchase Batches')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Fertilizer'),
        xl.TextCellValue('Qty Purchased'),
        xl.TextCellValue('Price'),
        xl.TextCellValue('Total'),
      ]);
      for (final r in purchaseRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 4.5 Organic Fertilizer Purchases
    if (organicFertilizerRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('4.5 Organic Fertilizer Purchases')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Organic Fertilizer Name'),
        xl.TextCellValue('Loads'),
        xl.TextCellValue('Unit'),
        xl.TextCellValue('Price'),
      ]);
      for (final r in organicFertilizerRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 5. Fertilizer Usage
    if (usageRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('5. Fertilizer Stock Usages')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Fertilizer'),
        xl.TextCellValue('Bags Used'),
        xl.TextCellValue('Remaining Stock'),
      ]);
      for (final r in usageRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 6. Tree Count
    if (treeCountRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('6. Tree Count Records')]);
      sheet.appendRow([
        xl.TextCellValue('Date Recorded'),
        xl.TextCellValue('Tree Name'),
        xl.TextCellValue('Plot'),
        xl.TextCellValue('Current Count'),
      ]);
      for (final r in treeCountRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 7. Tree Cuttings
    if (treeCuttingRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('7. Tree Cutting Logs')]);
      sheet.appendRow([
        xl.TextCellValue('Date Cut'),
        xl.TextCellValue('Tree Name'),
        xl.TextCellValue('Place'),
        xl.TextCellValue('Trees Cut'),
        xl.TextCellValue('Price/Tree'),
        xl.TextCellValue('Total Realized'),
      ]);
      for (final r in treeCuttingRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    // 8. Manager Told Salary
    if (managerSalaryRows.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('8. Manager Told Salary Logs')]);
      sheet.appendRow([
        xl.TextCellValue('From Date'),
        xl.TextCellValue('To Date'),
        xl.TextCellValue('Weekly Salary'),
        xl.TextCellValue('Created Date'),
      ]);
      for (final r in managerSalaryRows) {
        sheet.appendRow(r.map((e) => xl.TextCellValue(e)).toList());
      }
      sheet.appendRow([]); // spacing
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Estate_Dashboard_Report.xlsx");
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'ChinRam Reports Dashboard Spreadsheet');
    }
  }
}
