import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Mengeneingabe: Karton-Produkte mit zwei Feldern („Kartons“ und „Einzeln“),
/// kg-Produkte mit einem Feld und Komma (`12,5`), sonst ein ganzzahliges Feld.
/// Gerechnet wird nur mit ganzen Zahlen (Gramm, Stück).
class QuantityInput extends StatefulWidget {
  const QuantityInput({
    required this.value,
    required this.onChanged,
    this.unitsPerCarton,
    this.enabled = true,
    super.key,
  });

  final Quantity value;
  final ValueChanged<Quantity> onChanged;
  final int? unitsPerCarton;
  final bool enabled;

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late final TextEditingController _first;
  late final TextEditingController _second;
  late final FocusNode _firstFocus;
  late final FocusNode _secondFocus;

  bool get _cartonMode => widget.unitsPerCarton != null;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController();
    _second = TextEditingController();
    _firstFocus = _selectingFocus(_first);
    _secondFocus = _selectingFocus(_second);
    _sync();
  }

  @override
  void didUpdateWidget(covariant QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _sync();
  }

  FocusNode _selectingFocus(TextEditingController controller) {
    final focus = FocusNode();
    focus.addListener(() {
      if (focus.hasFocus) {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      }
    });
    return focus;
  }

  /// Schreibt den Wert in die Felder, außer ein Feld hat gerade den Fokus
  /// (sonst springt der Cursor beim Tippen).
  void _sync() {
    if (_firstFocus.hasFocus || _secondFocus.hasFocus) return;
    if (_cartonMode) {
      final parts = widget.value.splitIntoCartons(widget.unitsPerCarton!);
      _first.text = '${parts.cartons}';
      _second.text = '${parts.loosePieces}';
    } else {
      _first.text = QuantityFormatter.formatNumber(widget.value);
    }
  }

  void _emit() {
    if (_cartonMode) {
      widget.onChanged(
        Quantity.fromCartons(
          cartons: int.tryParse(_first.text) ?? 0,
          loosePieces: int.tryParse(_second.text) ?? 0,
          unitsPerCarton: widget.unitsPerCarton!,
          unit: widget.value.unit,
        ),
      );
      return;
    }
    final parsed = widget.value.unit.isWeight
        ? Quantity.tryParseKilograms(_first.text)
        : Quantity(int.tryParse(_first.text) ?? 0, widget.value.unit);
    if (parsed != null) widget.onChanged(parsed);
  }

  void _step(int delta) {
    final next = (widget.value.base + delta).clamp(0, 1 << 31);
    widget.onChanged(Quantity(next, widget.value.unit));
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final stepSize = widget.value.unit.isWeight ? 100 : 1;
    return Row(
      children: [
        IconButton(
          tooltip: '-',
          onPressed: widget.enabled ? () => _step(-stepSize) : null,
          icon: const Icon(AppIcons.minus),
        ),
        Expanded(
          child: _field(
            _first,
            _firstFocus,
            _cartonMode
                ? strings.cartons
                : widget.value.unit.isWeight
                ? QuantityLabels.de.kg
                : null,
          ),
        ),
        if (_cartonMode) ...[
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _field(_second, _secondFocus, strings.loosePieces)),
        ],
        IconButton(
          tooltip: '+',
          onPressed: widget.enabled ? () => _step(stepSize) : null,
          icon: const Icon(AppIcons.add),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    FocusNode focus,
    String? label,
  ) => TextField(
    controller: controller,
    focusNode: focus,
    enabled: widget.enabled,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    style: AppText.amount,
    keyboardType: TextInputType.numberWithOptions(
      decimal: widget.value.unit.isWeight,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        widget.value.unit.isWeight
            ? RegExp(r'^\d*[,.]?\d{0,3}')
            : RegExp(r'^\d*'),
      ),
    ],
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => _emit(),
  );
}
