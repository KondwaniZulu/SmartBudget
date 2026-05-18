String formatZmwFromNgwee(
  int amountNgwee, {
  bool withCode = true,
  bool showDecimals = true,
}) {
  final bool isNegative = amountNgwee < 0;
  final int absolute = amountNgwee.abs();
  final int kwacha = absolute ~/ 100;
  final int ngwee = absolute % 100;
  final String whole = _formatWhole(kwacha);
  final String decimals = showDecimals
      ? '.${ngwee.toString().padLeft(2, '0')}'
      : '';
  final String prefix = withCode ? 'ZMW ' : '';
  final String sign = isNegative ? '-' : '';
  return '$sign$prefix$whole$decimals';
}

int? parseZmwInputToNgwee(String raw) {
  final String normalized = raw.trim().replaceAll(',', '');
  if (normalized.isEmpty) {
    return null;
  }

  final double? value = double.tryParse(normalized);
  if (value == null) {
    return null;
  }

  return (value * 100).round();
}

String formatNgweeForInput(int amountNgwee) {
  final int absolute = amountNgwee.abs();
  final int kwacha = absolute ~/ 100;
  final int ngwee = absolute % 100;
  return '$kwacha.${ngwee.toString().padLeft(2, '0')}';
}

String _formatWhole(int value) {
  final String whole = value.toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
