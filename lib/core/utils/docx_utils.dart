import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

class DocxUtils {
  static List<String> extractTextFromBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final results = <String>[];
    ArchiveFile? docFile;
    try {
      docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
    } catch (e) {
      docFile = null;
    }
    if (docFile == null) {
      for (final file in archive) {
        if (file.name.endsWith('.xml') && file.name.contains('word/')) {
          results.addAll(_extractXmlText(file.content as List<int>));
        }
      }
    } else {
      results.addAll(_extractXmlText(docFile.content as List<int>));
    }
    return results;
  }

  static Future<List<String>> extractTextFromFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return extractTextFromBytes(bytes);
  }

  static List<String> _extractXmlText(List<int> xmlBytes) {
    final xmlString = utf8.decode(xmlBytes, allowMalformed: true);
    final results = <String>[];
    try {
      final tPattern = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
      for (final match in tPattern.allMatches(xmlString)) {
        final text = match.group(1)?.trim() ?? '';
        if (text.isNotEmpty) results.add(text);
      }
    } catch (e) {
      final textPattern = RegExp(r'>([^<]+)<');
      for (final match in textPattern.allMatches(xmlString)) {
        final text = match.group(1)?.trim() ?? '';
        if (text.isNotEmpty && !text.startsWith('<?xml')) results.add(text);
      }
    }
    return results;
  }

  static List<String> parseItemsFromText(List<String> lines) {
    final items = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'^[\d\s.,]+$').hasMatch(trimmed)) continue;
      if (trimmed.length < 2) continue;
      final cleaned = trimmed.replaceFirst(RegExp(r'^[\d]+[.)\-\s]+'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length >= 2) {
        if (!items.any((item) => item.toLowerCase() == cleaned.toLowerCase())) {
          items.add(cleaned);
        }
      }
    }
    return items;
  }

  static Future<List<int>> createRequestDocx({
    required String title,
    required String date,
    String? department,
    String? requester,
    String? signature,
    required List<Map<String, dynamic>> items,
  }) async {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buf.writeln('  <w:body>');
    buf.writeln('    <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_esc(title)}</w:t></w:r></w:p>');
    buf.writeln('    <w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>Date: ${_esc(date)}</w:t></w:r></w:p>');
    if (department != null && department.isNotEmpty) {
      buf.writeln('    <w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>Department: ${_esc(department)}</w:t></w:r></w:p>');
    }
    if (requester != null && requester.isNotEmpty) {
      buf.writeln('    <w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>Requested by: ${_esc(requester)}</w:t></w:r></w:p>');
    }
    buf.writeln('    <w:p/>');
    buf.writeln('    <w:tbl>');
    buf.writeln('      <w:tblPr>');
    buf.writeln('        <w:tblBorders>');
    buf.writeln('          <w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('        </w:tblBorders>');
    buf.writeln('        <w:tblW w:w="5000" w:type="pct"/>');
    buf.writeln('      </w:tblPr>');
    // Header row
    buf.writeln('      <w:tr>');
    for (final h in ['#', 'Item Name', 'Quantity', 'Notes']) {
      buf.writeln('        <w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="1976D2"/></w:tcPr><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/><w:sz w:val="22"/></w:rPr><w:t>${_esc(h)}</w:t></w:r></w:p></w:tc>');
    }
    buf.writeln('      </w:tr>');
    // Data rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rowColor = i.isEven ? 'FFFFFF' : 'E3F2FD';
      buf.writeln('      <w:tr>');
      buf.writeln('        <w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$rowColor"/></w:tcPr><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>${_esc((i + 1).toString())}</w:t></w:r></w:p></w:tc>');
      buf.writeln('        <w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$rowColor"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>${_esc(item['itemName'] ?? '')}</w:t></w:r></w:p></w:tc>');
      buf.writeln('        <w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$rowColor"/></w:tcPr><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>${_esc(item['quantity']?.toString() ?? '')}</w:t></w:r></w:p></w:tc>');
      buf.writeln('        <w:tc><w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$rowColor"/></w:tcPr><w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t>${_esc(item['notes'] ?? '')}</w:t></w:r></w:p></w:tc>');
      buf.writeln('      </w:tr>');
    }
    buf.writeln('    </w:tbl>');
    buf.writeln('    <w:p/>');
    buf.writeln('  </w:body>');
    buf.writeln('</w:document>');

    final archive = Archive();
    final contentTypes = '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';
    final rels = '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    // prepare bytes for each file part
    final contentTypesBytes = utf8.encode(contentTypes);
    final relsBytes = utf8.encode(rels);
    final docRelsXml = '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';
    final docRelsBytes = utf8.encode(docRelsXml);
    final documentXmlBytes = utf8.encode(buf.toString());

    // add files to archive with correct sizes
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));
    archive.addFile(ArchiveFile('_rels/.rels', relsBytes.length, relsBytes));
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes));
    archive.addFile(ArchiveFile('word/document.xml', documentXmlBytes.length, documentXmlBytes));

    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) return <int>[];
    return zipped.toList();
  }

  static String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
