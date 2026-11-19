import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../farm/models/farm_income_model.dart';
import '../../farm/models/farm_expense_model.dart';
import '../../farm/models/farm_fertilizer_model.dart';
import '../../farm/models/farm_organic_fertilizer_model.dart';
import '../../farm/models/farm_fertilizer_usage_model.dart';
import '../../farm/models/farm_salary_model.dart';

class FarmReportExportHelper {
  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatDateStr(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return _formatDate(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatDecimal(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  static pw.Document getPdfDocument() => pw.Document();

  static Future<void> sharePdf({
    required String dateRange,
    required Map<String, String> summary,
    required List<FarmIncomeModel> incomeList,
    required List<FarmExpenseModel> expenseList,
    required List<FarmSalaryModel> salaryList,
    required List<FarmFertilizerModel> chemicalPurchases,
    required List<FarmOrganicFertilizerModel> organicPurchases,
    required List<FarmFertilizerUsageModel> chemicalUsages,
    required Map<String, String> chemNames,
    required Map<String, String> orgNames,
  }) async {
    final pdf = getPdfDocument();

    final List<List<String>> incomeRows = incomeList.map((item) {
      return [
        _formatDate(item.date),
        item.category,
        item.productName,
        '${item.quantity} ${item.unit}',
        '₹${item.pricePerUnit.toStringAsFixed(2)}',
        '₹${item.totalAmount.toStringAsFixed(2)}',
      ];
    }).toList();

    final List<List<String>> expenseRows = expenseList.map((item) {
      final sub = item.subCategory != null ? ' (${item.subCategory})' : '';
      String details = '';
      if (item.category.toLowerCase() == 'coconut') {
        details = 'Vettu count: ${item.vettuWorkersCount ?? 0}, Chithu: ${item.chithuWorkersCount ?? 0}';
      } else if (item.category.toLowerCase() == 'milk') {
        details = item.productName ?? 'Doctor/Others';
      } else {
        details = item.productName ?? '-';
      }
      return [
        _formatDate(item.date),
        '${item.category}$sub',
        details,
        '₹${item.amount.toStringAsFixed(2)}',
        item.notes ?? '-',
      ];
    }).toList();

    final List<List<String>> salaryRows = salaryList.map((item) {
      return [
        '${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}',
        item.work,
        '${item.numberOfPersons}',
        '₹${item.salaryAmount.toStringAsFixed(2)}',
        item.notes ?? '-',
      ];
    }).toList();

    final List<List<String>> chemPurchaseRows = chemicalPurchases.map((item) {
      return [
        _formatDateStr(item.date),
        item.name,
        '${_formatDecimal(item.initialStock)} Bags',
        '${item.quantityPerBag} Kg',
        '₹${item.price.toStringAsFixed(2)}',
      ];
    }).toList();

    final List<List<String>> orgPurchaseRows = organicPurchases.map((item) {
      return [
        _formatDateStr(item.date),
        item.name,
        '${_formatDecimal(item.loads)} Loads',
        item.unit,
        '₹${item.price.toStringAsFixed(2)}',
      ];
    }).toList();

    final List<List<String>> chemUsageRows = chemicalUsages.map((item) {
      final name = chemNames[item.fertilizerId] ?? 'Unknown';
      return [
        _formatDateStr(item.date),
        name,
        '${_formatDecimal(item.bagsUsed)} Bags',
        item.notes ?? '-',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Farm Reports Dashboard',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('ChinRam Estate, Farm & Dryer Management System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Report Period: $dateRange', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text('Generated On: ${DateTime.now().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text('Overall Financial Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#606C38'))),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: summary.entries.map((entry) {
                final isNetProfit = entry.key == 'Net Profit';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(entry.key, style: pw.TextStyle(fontWeight: isNetProfit ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.grey800, fontSize: 8)),
                      pw.Text(entry.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isNetProfit ? PdfColors.brown800 : PdfColors.grey900, fontSize: 8)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 16),

          if (incomeRows.isNotEmpty) ...[
            pw.Text('1. Farm Income Records', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Category', 'Product Name', 'Quantity', 'Rate', 'Total Amount'],
              data: incomeRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],

          if (expenseRows.isNotEmpty) ...[
            pw.Text('2. Farm Expense Records', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Category', 'Details', 'Amount', 'Notes'],
              data: expenseRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],

          if (salaryRows.isNotEmpty) ...[
            pw.Text('3. Farm Salary Records', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Period', 'Work Done', 'Workers', 'Amount', 'Notes'],
              data: salaryRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],

          if (chemPurchaseRows.isNotEmpty) ...[
            pw.Text('4. Chemical Fertilizer Purchases', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Fertilizer Name', 'Bags Purchased', 'Qty/Bag', 'Price'],
              data: chemPurchaseRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],

          if (orgPurchaseRows.isNotEmpty) ...[
            pw.Text('5. Organic Fertilizer Purchases', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Fertilizer Name', 'Loads Purchased', 'Vehicle Type', 'Price'],
              data: orgPurchaseRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],

          if (chemUsageRows.isNotEmpty) ...[
            pw.Text('6. Chemical Stock Usages', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Fertilizer Name', 'Bags Used', 'Notes'],
              data: chemUsageRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              cellHeight: 18,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Farm_Dashboard_Report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'ChinRam Farm Reports Dashboard Document');
  }

  static Future<void> shareExcel({
    required String dateRange,
    required Map<String, String> summary,
    required List<FarmIncomeModel> incomeList,
    required List<FarmExpenseModel> expenseList,
    required List<FarmSalaryModel> salaryList,
    required List<FarmFertilizerModel> chemicalPurchases,
    required List<FarmOrganicFertilizerModel> organicPurchases,
    required List<FarmFertilizerUsageModel> chemicalUsages,
    required Map<String, String> chemNames,
    required Map<String, String> orgNames,
  }) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    sheet.appendRow([xl.TextCellValue('Farm Reports Dashboard')]);
    sheet.appendRow([xl.TextCellValue('Report Period: $dateRange')]);
    sheet.appendRow([xl.TextCellValue('Generated On: ${DateTime.now().toString().split('.')[0]}')]);
    sheet.appendRow([]);

    sheet.appendRow([xl.TextCellValue('Financial Summary KPIs')]);
    for (final entry in summary.entries) {
      sheet.appendRow([xl.TextCellValue(entry.key), xl.TextCellValue(entry.value)]);
    }
    sheet.appendRow([]);

    if (incomeList.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('1. Farm Income Records')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Product Name'),
        xl.TextCellValue('Quantity'),
        xl.TextCellValue('Rate'),
        xl.TextCellValue('Total Amount'),
      ]);
      for (final item in incomeList) {
        sheet.appendRow([
          xl.TextCellValue(_formatDate(item.date)),
          xl.TextCellValue(item.category),
          xl.TextCellValue(item.productName),
          xl.TextCellValue('${item.quantity} ${item.unit}'),
          xl.TextCellValue('₹${item.pricePerUnit.toStringAsFixed(2)}'),
          xl.TextCellValue('₹${item.totalAmount.toStringAsFixed(2)}'),
        ]);
      }
      sheet.appendRow([]);
    }

    if (expenseList.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('2. Farm Expense Records')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Details'),
        xl.TextCellValue('Amount'),
        xl.TextCellValue('Notes'),
      ]);
      for (final item in expenseList) {
        final sub = item.subCategory != null ? ' (${item.subCategory})' : '';
        String details = '';
        if (item.category.toLowerCase() == 'coconut') {
          details = 'Vettu count: ${item.vettuWorkersCount ?? 0}, Chithu: ${item.chithuWorkersCount ?? 0}';
        } else if (item.category.toLowerCase() == 'milk') {
          details = item.productName ?? 'Doctor/Others';
        } else {
          details = item.productName ?? '-';
        }
        sheet.appendRow([
          xl.TextCellValue(_formatDate(item.date)),
          xl.TextCellValue('${item.category}$sub'),
          xl.TextCellValue(details),
          xl.TextCellValue('₹${item.amount.toStringAsFixed(2)}'),
          xl.TextCellValue(item.notes ?? '-'),
        ]);
      }
      sheet.appendRow([]);
    }

    if (salaryList.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('3. Farm Salary Records')]);
      sheet.appendRow([
        xl.TextCellValue('Period'),
        xl.TextCellValue('Work Done'),
        xl.TextCellValue('Workers'),
        xl.TextCellValue('Amount'),
        xl.TextCellValue('Notes'),
      ]);
      for (final item in salaryList) {
        sheet.appendRow([
          xl.TextCellValue('${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}'),
          xl.TextCellValue(item.work),
          xl.TextCellValue('${item.numberOfPersons}'),
          xl.TextCellValue('₹${item.salaryAmount.toStringAsFixed(2)}'),
          xl.TextCellValue(item.notes ?? '-'),
        ]);
      }
      sheet.appendRow([]);
    }

    if (chemicalPurchases.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('4. Chemical Fertilizer Purchases')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Fertilizer Name'),
        xl.TextCellValue('Bags Purchased'),
        xl.TextCellValue('Quantity/Bag'),
        xl.TextCellValue('Price'),
      ]);
      for (final item in chemicalPurchases) {
        sheet.appendRow([
          xl.TextCellValue(_formatDateStr(item.date)),
          xl.TextCellValue(item.name),
          xl.TextCellValue(_formatDecimal(item.initialStock)),
          xl.TextCellValue('${item.quantityPerBag} Kg'),
          xl.TextCellValue('₹${item.price.toStringAsFixed(2)}'),
        ]);
      }
      sheet.appendRow([]);
    }

    if (organicPurchases.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('5. Organic Fertilizer Purchases')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Fertilizer Name'),
        xl.TextCellValue('Loads Purchased'),
        xl.TextCellValue('Vehicle Type'),
        xl.TextCellValue('Price'),
      ]);
      for (final item in organicPurchases) {
        sheet.appendRow([
          xl.TextCellValue(_formatDateStr(item.date)),
          xl.TextCellValue(item.name),
          xl.TextCellValue(_formatDecimal(item.loads)),
          xl.TextCellValue(item.unit),
          xl.TextCellValue('₹${item.price.toStringAsFixed(2)}'),
        ]);
      }
      sheet.appendRow([]);
    }

    if (chemicalUsages.isNotEmpty) {
      sheet.appendRow([xl.TextCellValue('6. Chemical Stock Usages')]);
      sheet.appendRow([
        xl.TextCellValue('Date'),
        xl.TextCellValue('Fertilizer Name'),
        xl.TextCellValue('Bags Used'),
        xl.TextCellValue('Notes'),
      ]);
      for (final item in chemicalUsages) {
        final name = chemNames[item.fertilizerId] ?? 'Unknown';
        sheet.appendRow([
          xl.TextCellValue(_formatDateStr(item.date)),
          xl.TextCellValue(name),
          xl.TextCellValue(_formatDecimal(item.bagsUsed)),
          xl.TextCellValue(item.notes ?? '-'),
        ]);
      }
      sheet.appendRow([]);
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Farm_Dashboard_Report.xlsx");
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'ChinRam Farm Reports Dashboard Spreadsheet');
    }
  }
}
