extension StringExtensions on String {
  /// Split at first occurrence of separator
  /// Returns [before, after] or [original] if separator not found
  List<String> splitAtFirst(String separator) {
    final index = indexOf(separator);
    if (index == -1) return [this];

    return [substring(0, index), substring(index + separator.length)];
  }
}
