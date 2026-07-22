import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/baber_app.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:app_links/app_links.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/booking/domain/booking_repository.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/notifications/domain/notifications_repository.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockTenantRepository extends Mock implements TenantRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}
class MockBookingRepository extends Mock implements BookingRepository {}
class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}
class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockNotificationsRepository extends Mock implements NotificationsRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAppLinks extends Mock implements AppLinks {}

void main() {
  testWidgets('app boots to tenant selection when no session or deep link is stored', (tester) async {
    final tokenStorage = MockTokenStorage();
    final tenantStorage = MockTenantStorage();
    final tenantRepository = MockTenantRepository();
    final appLinks = MockAppLinks();
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => null);
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);
    // TenantSelectionScreen dispatches LoadTenants on mount.
    when(() => tenantRepository.listTenants()).thenAnswer((_) async => const Right(<Tenant>[]));

    await tester.pumpWidget(BaberApp(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: MockAuthRepository(),
      tenantRepository: tenantRepository,
      serviceRepository: MockServiceRepository(),
      bookingRepository: MockBookingRepository(),
      loyaltyRepository: MockLoyaltyRepository(),
      appointmentRepository: MockAppointmentRepository(),
      notificationsRepository: MockNotificationsRepository(),
      profileRepository: MockProfileRepository(),
      appLinks: appLinks,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Escolha a barbearia'), findsOneWidget);
  });
}
