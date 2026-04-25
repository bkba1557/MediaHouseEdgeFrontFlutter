class ServiceFolderOption {
  final String collectionKey;
  final String collectionTitle;

  const ServiceFolderOption({
    required this.collectionKey,
    required this.collectionTitle,
  });

  factory ServiceFolderOption.fromTitle(String title) {
    final normalizedTitle = normalizeFolderTitle(title);
    return ServiceFolderOption(
      collectionKey: buildCollectionKey(normalizedTitle),
      collectionTitle: normalizedTitle,
    );
  }
}

const Set<String> _requiredFolderCategories = {
  'series_movies',
  'artist_contracts',
  'commercial_ads',
};

const Map<String, List<String>> _defaultFolderTitlesByCategory = {
  'artist_contracts': ['مطربين ومطربات', 'فنانيين شعبي', 'مهرجنات شعبية'],
  'commercial_ads': [
    'المجال الطبي',
    'مطاعم وكافيهات',
    'مقاولات واستثمار عقاري',
    'منتجات',
    'اخر',
  ],
};

bool serviceCategoryRequiresFolder(String category) {
  return _requiredFolderCategories.contains(category.trim());
}

List<ServiceFolderOption> defaultFoldersForCategory(String category) {
  final titles = _defaultFolderTitlesByCategory[category.trim()] ?? const [];
  return titles.map(ServiceFolderOption.fromTitle).toList(growable: false);
}

String normalizeFolderTitle(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String buildCollectionKey(String value) {
  final normalized = normalizeFolderTitle(value).toLowerCase();
  return normalized
      .replaceAll(RegExp(r'[\\/#?%&+]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
}
