/// Platz für Zeilen ohne Produkt (freie Positionen): ganz ans Ende.
const int _lastPlace = 1 << 62;

/// Ordnet [rows] in die eigene Produkt-Reihenfolge (`products.sort_order`).
///
/// [sortOrder] liefert den Platz des Produkts einer Zeile, `null` bei Zeilen
/// ohne Produkt. Diese bleiben am Ende, untereinander in ihrer bisherigen
/// Reihenfolge; ebenso Zeilen mit gleichem Platz.
List<T> sortByProductOrder<T>(
  Iterable<T> rows,
  int? Function(T row) sortOrder,
) {
  final indexed =
      [for (final row in rows.indexed) (index: row.$1, value: row.$2)]
        ..sort((a, b) {
          final byPlace = (sortOrder(a.value) ?? _lastPlace).compareTo(
            sortOrder(b.value) ?? _lastPlace,
          );
          return byPlace != 0 ? byPlace : a.index.compareTo(b.index);
        });
  return [for (final row in indexed) row.value];
}
