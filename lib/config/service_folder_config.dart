class ServiceFolderOption {
  final String collectionKey;
  final String collectionTitle;
  final int? sortOrder;

  const ServiceFolderOption({
    required this.collectionKey,
    required this.collectionTitle,
    this.sortOrder,
  });

  factory ServiceFolderOption.fromTitle(String title, {int? sortOrder}) {
    final normalizedTitle = normalizeFolderTitle(title);
    return ServiceFolderOption(
      collectionKey: buildCollectionKey(normalizedTitle),
      collectionTitle: normalizedTitle,
      sortOrder: sortOrder,
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
  return titles
      .asMap()
      .entries
      .map(
        (entry) =>
            ServiceFolderOption.fromTitle(entry.value, sortOrder: entry.key),
      )
      .toList(growable: false);
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

int compareFolderOptions(ServiceFolderOption a, ServiceFolderOption b) {
  final aOrder = a.sortOrder;
  final bOrder = b.sortOrder;

  if (aOrder != null && bOrder != null) {
    final byOrder = aOrder.compareTo(bOrder);
    if (byOrder != 0) return byOrder;
  } else if (aOrder != null) {
    return -1;
  } else if (bOrder != null) {
    return 1;
  }

  return a.collectionTitle.compareTo(b.collectionTitle);
}
