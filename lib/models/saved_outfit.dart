import 'dart:convert';
import 'outfit_analysis.dart';

class SavedOutfit {
  final String id;
  final String imagePath;
  final OutfitAnalysis analysis;
  final DateTime savedAt;
  final List<String> tags;
  final bool isFavorite;

  const SavedOutfit({
    required this.id,
    required this.imagePath,
    required this.analysis,
    required this.savedAt,
    this.tags = const [],
    this.isFavorite = false,
  });

  SavedOutfit copyWith({List<String>? tags, bool? isFavorite}) {
    return SavedOutfit(
      id: id,
      imagePath: imagePath,
      analysis: analysis,
      savedAt: savedAt,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'savedAt': savedAt.toIso8601String(),
    'tags': tags,
    'isFavorite': isFavorite,
    'analysis': {
      'overallStyle': analysis.overallStyle,
      'colorPalette': analysis.colorPalette,
      'occasion': analysis.occasion,
      'fitAssessment': analysis.fitAssessment,
      'strengths': analysis.strengths,
      'improvements': analysis.improvements,
      'accessorySuggestions': analysis.accessorySuggestions,
      'alternativeOutfits': analysis.alternativeOutfits,
      'seasonalAdvice': analysis.seasonalAdvice,
      'styleScore': analysis.styleScore,
      'stylePersona': analysis.stylePersona,
    },
  };

  factory SavedOutfit.fromJson(Map<String, dynamic> json) {
    final a = json['analysis'] as Map<String, dynamic>;
    return SavedOutfit(
      id: json['id'],
      imagePath: json['imagePath'],
      savedAt: DateTime.parse(json['savedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      analysis: OutfitAnalysis(
        overallStyle: a['overallStyle'] ?? '',
        colorPalette: a['colorPalette'] ?? '',
        occasion: a['occasion'] ?? '',
        fitAssessment: a['fitAssessment'] ?? '',
        strengths: List<String>.from(a['strengths'] ?? []),
        improvements: List<String>.from(a['improvements'] ?? []),
        accessorySuggestions: List<String>.from(
          a['accessorySuggestions'] ?? [],
        ),
        alternativeOutfits: List<String>.from(a['alternativeOutfits'] ?? []),
        seasonalAdvice: a['seasonalAdvice'] ?? '',
        styleScore: a['styleScore'] ?? 0,
        stylePersona: a['stylePersona'] ?? '',
      ),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory SavedOutfit.fromJsonString(String s) =>
      SavedOutfit.fromJson(jsonDecode(s));
}
