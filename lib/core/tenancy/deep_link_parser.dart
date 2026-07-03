class DeepLinkParser {
  static String? extractTenantSlug(Uri uri) {
    if (uri.scheme != 'baber') return null;
    if (uri.host != 't') return null;
    if (uri.pathSegments.isEmpty) return null;
    final slug = uri.pathSegments.first;
    return slug.isEmpty ? null : slug;
  }
}
