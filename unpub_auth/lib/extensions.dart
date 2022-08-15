import 'dart:convert';

extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension EnumExtensions on List {
  T? parse<T>(String value) {
    return where((type) => type.toString().split('.').last == value).firstOrNull as T?;
  }
}

extension StringExtensions on String {
  String urlEncode() => Uri.encodeComponent(this);
  Map<String, dynamic> decodeJson() => jsonDecode(this);

  String padBoth(int paddedLength) {
    if (paddedLength <= length) return this;
    final left = ((paddedLength - length) / 2).floor();
    return padLeft(left + length) + ''.padRight(paddedLength - length - left);
  }

  List<String> wrap(int wrapLength, {int? maxLines}) {
    if (length < wrapLength) return [this];

    final lines = <String>[];
    final words = split(' ');
    for (String word in words) {
      if (lines.isEmpty) {
        _addNewWord(lines, word, wrapLength);
      } else {
        String lastLine = lines.last;

        if (lastLine.length + word.length < wrapLength) {
          lastLine = lastLine + word + ' ';
          lines.last = lastLine;
        } else if (lastLine.length + word.length == wrapLength) {
          lastLine = lastLine + word;
          lines.last = lastLine;
        } else {
          if (_isThereMuchSpace(lastLine, wrapLength.toDouble())) {
            _breakLongWord(lines, word, wrapLength, lastLine.length);
          } else {
            _addNewWord(lines, word, wrapLength);
          }
        }
      }
    }

    if (maxLines != null && lines.length > maxLines) {
      lines.removeRange(maxLines, lines.length);
      lines[maxLines - 1] = lines[maxLines - 1].substring(0, wrapLength - 3) + '...';
    }

    return lines;
  }

  void _addNewWord(List<String> resultList, String word, int wrapLength) {
    if (word.length < wrapLength) {
      resultList.add(word + ' ');
    } else if (word.length == wrapLength) {
      resultList.add(word);
    } else {
      _breakLongWord(resultList, word, wrapLength, 0);
    }
  }

  void _breakLongWord(List<String> resultList, String word, int wrapLength, int offset) {
    String part = word.substring(0, (wrapLength - offset) - 1);
    if (offset > 1) {
      String lastLine = resultList.last;
      lastLine = lastLine + part + '-';
      resultList.last = lastLine;
    } else {
      resultList.add(part + '-');
    }

    String nextPart = word.substring((wrapLength - offset) - 1, word.length);
    if (nextPart.length > wrapLength) {
      _breakLongWord(resultList, nextPart, wrapLength, 0);
    } else if (nextPart.length == wrapLength) {
      resultList.add(nextPart);
    } else {
      resultList.add(nextPart + ' ');
    }
  }

  bool _isThereMuchSpace(String line, double lineLength) {
    double expectedPercent = (lineLength * 65) / 100;
    if (line.length <= expectedPercent) return true;
    return false;
  }
}
