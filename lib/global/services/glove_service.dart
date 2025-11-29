// lib/feature/glove/glove_service.dart

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class GloveService {
  List<String>? _vocab;
  Float32List? _vectors;
  Map<String, int>? _wordIndex;
  final int _dimensions = 50;
  bool _isInitialized = false;

  // Common words to skip
  static const _stopwords = {
    'the',
    'and',
    'for',
    'are',
    'but',
    'not',
    'you',
    'all',
    'can',
    'her',
    'was',
    'one',
    'our',
    'out',
    'has',
    'have',
    'been',
    'were',
    'they',
    'their',
    'what',
    'when',
    'where',
    'which',
    'this',
    'that',
    'with',
    'from',
    'will',
    'would',
    'there',
    'these',
    'than',
    'then',
    'into',
    'some',
    'such',
    'only',
    'other',
    'also',
    'just',
    'more',
    'most',
    'very',
  };

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('📦 Loading GloVe vocabulary...');
    final vocabString = await rootBundle.loadString('assets/glove/glove_vocab.json');
    _vocab = List<String>.from(json.decode(vocabString));

    _wordIndex = {};
    for (int i = 0; i < _vocab!.length; i++) {
      _wordIndex![_vocab![i]] = i;
    }

    print('📦 Loading GloVe vectors...');
    final vectorData = await rootBundle.load('assets/glove/glove_vectors.bin');
    _vectors = vectorData.buffer.asFloat32List();

    _isInitialized = true;
    print('✅ GloVe loaded: ${_vocab!.length} words');
  }

  /// Expand a topic using centroid search
  String expandTopic(String topicName, {int maxRelated = 10, double minSimilarity = 0.45}) {
    if (!_isInitialized) {
      print('⚠️ GloVe not initialized, returning original');
      return topicName;
    }

    // Parse input words
    final inputWords = topicName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !_stopwords.contains(w))
        .toList();

    if (inputWords.isEmpty) return topicName;

    // Build centroid vector (average of all input words)
    final centroid = Float32List(_dimensions);
    int foundCount = 0;

    for (final word in inputWords) {
      final idx = _wordIndex![word];
      if (idx != null) {
        final vec = _getVector(idx);
        for (int i = 0; i < _dimensions; i++) {
          centroid[i] += vec[i];
        }
        foundCount++;
      }
    }

    if (foundCount == 0) {
      print('⚠️ No input words found in vocabulary');
      return topicName;
    }

    // Average
    for (int i = 0; i < _dimensions; i++) {
      centroid[i] /= foundCount;
    }

    // Find words nearest to centroid
    final candidates = <_WordScore>[];

    for (int i = 0; i < _vocab!.length; i++) {
      final word = _vocab![i];

      // Skip input words
      if (inputWords.contains(word)) continue;

      // Skip stopwords
      if (_stopwords.contains(word)) continue;

      final similarity = _cosineSimilarity(centroid, _getVector(i));

      // Minimum threshold
      if (similarity < minSimilarity) continue;

      candidates.add(_WordScore(i, similarity));
    }

    // Sort by similarity
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Deduplicate stems and ensure diversity
    final selected = <String>[];
    final stems = <String>{};

    for (final candidate in candidates) {
      if (selected.length >= maxRelated) break;

      final word = _vocab![candidate.index];
      final stem = _getStem(word);

      // Skip if we already have this stem
      if (stems.contains(stem)) continue;

      // Skip if too similar to already selected words
      if (_tooSimilarToSelected(candidate.index, selected)) continue;

      selected.add(word);
      stems.add(stem);
    }

    final expanded = [...inputWords, ...selected];
    print('📝 Expanded "$topicName" → "${expanded.join(' ')}"');
    return expanded.join(' ');
  }

  /// Simple stemming (just truncate to first 5 chars)
  String _getStem(String word) {
    if (word.length <= 5) return word;
    return word.substring(0, 5);
  }

  /// Check if word is too similar to already selected words
  bool _tooSimilarToSelected(int candidateIndex, List<String> selected) {
    if (selected.isEmpty) return false;

    final candidateVec = _getVector(candidateIndex);

    for (final selectedWord in selected) {
      final selectedIdx = _wordIndex![selectedWord];
      if (selectedIdx == null) continue;

      final similarity = _cosineSimilarity(candidateVec, _getVector(selectedIdx));
      if (similarity > 0.8) return true; // Too similar
    }

    return false;
  }

  /// Find related words for a single word
  List<String> findRelatedWords(String word, {int topK = 10}) {
    if (!_isInitialized) throw Exception('GloVe not initialized');

    final lowerWord = word.toLowerCase();
    final wordIndex = _wordIndex![lowerWord];

    if (wordIndex == null) {
      print('⚠️ Word "$word" not in vocabulary');
      return [];
    }

    final wordVector = _getVector(wordIndex);
    final similarities = <_WordScore>[];

    for (int i = 0; i < _vocab!.length; i++) {
      if (i == wordIndex) continue;
      if (_stopwords.contains(_vocab![i])) continue;

      final similarity = _cosineSimilarity(wordVector, _getVector(i));
      similarities.add(_WordScore(i, similarity));
    }

    similarities.sort((a, b) => b.score.compareTo(a.score));

    return similarities.take(topK).map((e) => _vocab![e.index]).toList();
  }

  bool hasWord(String word) {
    return _wordIndex?.containsKey(word.toLowerCase()) ?? false;
  }

  Float32List _getVector(int index) {
    final start = index * _dimensions;
    return Float32List.sublistView(_vectors!, start, start + _dimensions);
  }

  double _cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0, normA = 0, normB = 0;

    for (int i = 0; i < _dimensions; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  void dispose() {
    _vocab = null;
    _vectors = null;
    _wordIndex = null;
    _isInitialized = false;
  }
}

class _WordScore {
  final int index;
  final double score;

  _WordScore(this.index, this.score);
}
