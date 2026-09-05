import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// One field (column heading + value) inside an [AppRecordCard].
class AppRecordField {
  final String label;
  final String value;
  const AppRecordField(this.label, this.value);
}

/// Renders one table row as a card: the first column promoted to a bold
/// title, remaining columns as a 2-column grid of single-line "Label: Value"
/// fields below (paired into explicit `Row`s rather than a `Wrap`, so it's
/// always 2 columns regardless of screen width — a `Wrap` of fixed-width
/// boxes silently degenerated to 1 column on narrower phones, making cards
/// with many fields far taller than necessary). A generic "table row as
/// card" widget for record lists where columns are arbitrary/dynamic (not a
/// fixed typed model) — e.g. OT Reports' 16 report types, each with
/// different headings from the backend. Mirrors report_channel_screen.dart's
/// `_PatientCard` visual language (white rounded card, bold title,
/// muted-label/dark-value text) so record lists look consistent across the
/// app, without needing a bespoke card per report type.
class AppRecordCard extends StatelessWidget {
  final String title;
  final List<AppRecordField> fields;
  final Widget? trailing;

  const AppRecordCard({super.key, required this.title, required this.fields, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryA10),
        boxShadow: [BoxShadow(color: AppColors.primaryA06, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF18324A))),
            ),
            ?trailing,
          ]),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.primaryA08),
            const SizedBox(height: 10),
            for (var i = 0; i < fields.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _field(fields[i])),
                  const SizedBox(width: 14),
                  Expanded(child: i + 1 < fields.length ? _field(fields[i + 1]) : const SizedBox.shrink()),
                ]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _field(AppRecordField f) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: '${f.label}: ', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7D93))),
        TextSpan(text: f.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF18324A))),
      ]),
    );
  }
}
