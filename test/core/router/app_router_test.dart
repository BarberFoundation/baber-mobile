import 'package:app_links/app_links.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/router/app_router.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/booking/domain/booking_repository.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/notifications/domain/notifications_repository.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockTenantRepository extends Mock implements TenantRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}
class MockBookingRepository extends Mock implements BookingRepository {}
class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockNotificationsRepository extends Mock implements NotificationsRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAppLinks extends Mock implements AppLinks {}

void main() {
  testWidgets('booking route without a Service extra redirects to the catalog (C8)', (tester) async {
    final serviceRepository = MockServiceRepository();
    when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right(<Service>[]));
    // Splash monta em '/' e resolve a rota inicial antes do go() do teste.
    final tokenStorage = MockTokenStorage();
    final tenantStorage = MockTenantStorage();
    final appLinks = MockAppLinks();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => null);
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);

    final router = buildAppRouter(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: MockAuthRepository(),
      tenantRepository: MockTenantRepository(),
      serviceRepository: serviceRepository,
      bookingRepository: MockBookingRepository(),
      appointmentRepository: MockAppointmentRepository(),
      notificationsRepository: MockNotificationsRepository(),
      profileRepository: MockProfileRepository(),
      appLinks: appLinks,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Simula restore de processo: rota de booking sem o extra (go_router não
    // serializa objetos).
    router.go('/booking/date');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum serviço disponível no momento.'), findsOneWidget);
  });
}
