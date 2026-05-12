class OutfitAnalysis {
  final String overallStyle;
  final String colorPalette;
  final String occasion;
  final String fitAssessment;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> accessorySuggestions;
  final List<String> alternativeOutfits;
  final String seasonalAdvice;
  final int styleScore;
  final String stylePersona;

  const OutfitAnalysis({
    required this.overallStyle,
    required this.colorPalette,
    required this.occasion,
    required this.fitAssessment,
    required this.strengths,
    required this.improvements,
    required this.accessorySuggestions,
    required this.alternativeOutfits,
    required this.seasonalAdvice,
    required this.styleScore,
    required this.stylePersona,
  });

  factory OutfitAnalysis.fromText(String rawText) {
    // Parse sections from Gemini's structured response
    String extract(String key) {
      final regex = RegExp(
        '$key:\\s*(.+?)(?=\\n[A-Z]|\\\$)',
        dotAll: true,
        caseSensitive: false,
      );
      return regex.firstMatch(rawText)?.group(1)?.trim() ?? 'Not available';
    }

    List<String> extractList(String key) {
      final regex = RegExp(
        '${key}:[\\s\\S]*?(?=\\n[A-Z_]+:|\\\$)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(rawText);
      if (match == null) return [];
      final block = match.group(0) ?? '';
      return RegExp(r'[-•]\s*(.+)')
          .allMatches(block)
          .map((m) => m.group(1)?.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    int score = 75;
    final scoreMatch = RegExp(r'STYLE_SCORE:\s*(\d+)').firstMatch(rawText);
    if (scoreMatch != null)
      score = int.tryParse(scoreMatch.group(1) ?? '75') ?? 75;

    return OutfitAnalysis(
      overallStyle: extract('OVERALL_STYLE'),
      colorPalette: extract('COLOR_PALETTE'),
      occasion: extract('OCCASION'),
      fitAssessment: extract('FIT_ASSESSMENT'),
      strengths: extractList('STRENGTHS'),
      improvements: extractList('IMPROVEMENTS'),
      accessorySuggestions: extractList('ACCESSORIES'),
      alternativeOutfits: extractList('ALTERNATIVES'),
      seasonalAdvice: extract('SEASONAL_ADVICE'),
      styleScore: score.clamp(0, 100),
      stylePersona: extract('STYLE_PERSONA'),
    );
  }
}
