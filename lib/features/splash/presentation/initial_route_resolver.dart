import 'package:app_links/app_links.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/tenancy/deep_link_parser.dart';
import '../../../core/tenancy/tenant_storage.dart';
import '../../tenant_selection/domain/tenant_repository.dart';

class InitialRouteResolver {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final TenantRepository tenantRepository;
  final AppLinks appLinks;

  const InitialRouteResolver({
    required this.tokenStorage,
    required this.tenantStorage,
    required this.tenantRepository,
    required this.appLinks,
  });

  Future<String> resolve() async {
    final tenantId = await tenantStorage.readTenantId();
    final accessToken = await tokenStorage.readAccessToken();

    if (tenantId != null && accessToken != null) return '/home';
    if (tenantId != null) return '/phone';

    final initialUri = await appLinks.getInitialLink();
    final slug = initialUri == null ? null : DeepLinkParser.extractTenantSlug(initialUri);
    if (slug == null) return '/tenant-selection';

    final result = await tenantRepository.findBySlug(slug);
    String? nextRoute;
    await result.fold(
      (_) async => nextRoute = null,
      (tenant) async {
        await tenantStorage.saveTenant(id: tenant.id, slug: tenant.slug);
        nextRoute = '/phone';
      },
    );
    return nextRoute ?? '/tenant-selection';
  }
}
