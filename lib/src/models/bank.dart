class Bank {
  final String name;
  final String? slug;
  final String code;
  final String? ussd;
  final int popularity;

  const Bank({
    required this.name,
    required this.code,
    this.slug,
    this.ussd,
    this.popularity = 0,
  });

  /// Returns the path to the bank's logo asset.
  String get logo {
    //TODO return default logo.
    if (slug == null) return "undefined";
    return 'packages/nigerian_banks_nuban/assets/logos/$slug.png';
  }

  @override
  String toString() {
    return 'Bank(name: $name, slug: $slug, code: $code, ussd: $ussd)';
  }
}
