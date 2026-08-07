library;

/// Rule-based UPSC & Exam subject classifier for ingested evidence objects.
class CategoryClassifier {
  static const List<String> supportedCategories = [
    'Polity',
    'Economy',
    'Environment',
    'Science',
    'Agriculture',
    'Governance',
    'International Relations',
    'Security',
    'Social Justice',
    'Culture',
    'Technology',
  ];

  static const Map<String, List<String>> _keywordMap = {
    'Polity': [
      'parliament',
      'constitution',
      'bill',
      'act',
      'supreme court',
      'high court',
      'judiciary',
      'election',
      'amendment',
      'article',
    ],
    'Economy': [
      'rbi',
      'sebi',
      'gdp',
      'repo rate',
      'inflation',
      'fiscal',
      'budget',
      'tax',
      'banking',
      'imf',
      'world bank',
      'trade',
    ],
    'Environment': [
      'climate',
      'cop',
      'biodiversity',
      'pollution',
      'green hydrogen',
      'renewable',
      'forest',
      'emission',
      'solar',
      'wildlife',
    ],
    'Science': [
      'isro',
      'drdo',
      'space',
      'satellite',
      'physics',
      'quantum',
      'who',
      'health',
      'vaccine',
      'medical',
    ],
    'Agriculture': [
      'kisan',
      'crop',
      'msp',
      'fertilizer',
      'irrigation',
      'farming',
      'icar',
      'monsoon',
      'soil',
    ],
    'Governance': [
      'scheme',
      'niti aayog',
      'digital india',
      'yojana',
      'direct benefit',
      'e-governance',
      'transparency',
      'cag',
      'pib',
    ],
    'International Relations': [
      'un',
      'g20',
      'brics',
      'quad',
      'bilateral',
      'summit',
      'treaty',
      'diplomacy',
      'embassy',
      'mou',
    ],
    'Security': [
      'defence',
      'army',
      'navy',
      'air force',
      'border',
      'cybersecurity',
      'terror',
      'missile',
    ],
    'Social Justice': [
      'caste',
      'tribal',
      'women',
      'poverty',
      'education',
      'disability',
      'welfare',
      'human rights',
    ],
    'Culture': [
      'heritage',
      'unesco',
      'monument',
      'art',
      'festival',
      'archaeology',
      'museum',
      'language',
    ],
    'Technology': [
      'ai',
      'semiconductor',
      '5g',
      '6g',
      'blockchain',
      'cyber',
      'supercomputer',
      'software',
    ],
  };

  /// Classify title and summary text into primary UPSC category.
  static String classifyCategory(String title, String summary) {
    final combined = '$title $summary'.toLowerCase();

    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (combined.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Governance'; // Default fallback category
  }

  /// Generate appropriate keyword tags based on content matching.
  static List<String> extractTags(String title, String summary) {
    final combined = '$title $summary'.toLowerCase();
    final matchedTags = <String>{};

    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (combined.contains(keyword)) {
          matchedTags.add(keyword.toUpperCase());
        }
      }
    }

    return matchedTags.take(8).toList();
  }
}
