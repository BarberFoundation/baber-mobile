import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/core/tenancy/deep_link_parser.dart';

void main() {
  group('DeepLinkParser', () {
    test('extracts slug from baber://t/{slug}', () {
      final slug = DeepLinkParser.extractTenantSlug(Uri.parse('baber://t/barbearia-do-amigo'));
      expect(slug, 'barbearia-do-amigo');
    });

    test('returns null for unrelated scheme', () {
      final slug = DeepLinkParser.extractTenantSlug(Uri.parse('https://example.com/foo'));
      expect(slug, isNull);
    });

    test('returns null when path has no segments', () {
      final slug = DeepLinkParser.extractTenantSlug(Uri.parse('baber://t/'));
      expect(slug, isNull);
    });
  });
}
