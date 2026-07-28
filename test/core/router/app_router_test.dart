import 'package:app_links/app_links.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:baber_mobile/core/auth/token_storage.dart';
import 'package:baber_mobile/core/router/app_router.dart';
import 'package:baber_mobile/core/tenancy/tenant_storage.dart';
import 'package:baber_mobile/features/appointments/domain/appointment_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_repository.dart';
import 'package:baber_mobile/features/auth/domain/auth_user.dart';
import 'package:baber_mobile/features/booking/domain/barber.dart';
import 'package:baber_mobile/features/booking/domain/barber_repository.dart';
import 'package:baber_mobile/features/booking/domain/booking_repository.dart';
import 'package:baber_mobile/features/booking/domain/time_slot.dart';
import 'package:baber_mobile/features/catalog/domain/service.dart';
import 'package:baber_mobile/features/catalog/domain/service_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/loyalty_repository.dart';
import 'package:baber_mobile/features/loyalty/domain/subscription_tier_view.dart';
import 'package:baber_mobile/features/notifications/domain/notifications_repository.dart';
import 'package:baber_mobile/features/profile/domain/profile_repository.dart';
import 'package:baber_mobile/features/tenant_selection/domain/tenant_repository.dart';

class MockTokenStorage extends Mock implements TokenStorage {}
class MockTenantStorage extends Mock implements TenantStorage {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockTenantRepository extends Mock implements TenantRepository {}
class MockServiceRepository extends Mock implements ServiceRepository {}
class MockBookingRepository extends Mock implements BookingRepository {}
class MockBarberRepository extends Mock implements BarberRepository {}
class MockAppointmentRepository extends Mock implements AppointmentRepository {}
class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}
class MockNotificationsRepository extends Mock implements NotificationsRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAppLinks extends Mock implements AppLinks {}

void main() {
  GoRouter buildRouter({BookingRepository? bookingRepository, LoyaltyRepository? loyaltyRepository}) {
    final serviceRepository = MockServiceRepository();
    when(() => serviceRepository.listServices()).thenAnswer((_) async => const Right(<Service>[]));
    // Splash monta em '/' e resolve a rota inicial antes do go() do teste.
    final tokenStorage = MockTokenStorage();
    final tenantStorage = MockTenantStorage();
    final appLinks = MockAppLinks();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'fake-token');
    when(() => tenantStorage.readTenantId()).thenAnswer((_) async => 'tenant-1');
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);
    final barberRepository = MockBarberRepository();
    when(() => barberRepository.listBarbers()).thenAnswer((_) async => const Right(<Barber>[]));
    final profileRepository = MockProfileRepository();
    when(() => profileRepository.getMe())
        .thenAnswer((_) async => const Right(AuthUser(id: 'u1', name: 'João', phone: '+5511999999999')));

    return buildAppRouter(
      tokenStorage: tokenStorage,
      tenantStorage: tenantStorage,
      authRepository: MockAuthRepository(),
      tenantRepository: MockTenantRepository(),
      serviceRepository: serviceRepository,
      bookingRepository: bookingRepository ?? MockBookingRepository(),
      barberRepository: barberRepository,
      appointmentRepository: MockAppointmentRepository(),
      loyaltyRepository: loyaltyRepository ?? MockLoyaltyRepository(),
      notificationsRepository: MockNotificationsRepository(),
      profileRepository: profileRepository,
      appLinks: appLinks,
    );
  }

  testWidgets('booking route without a Service extra redirects to the catalog (C8)', (tester) async {
    final router = buildRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Simula restore de processo: rota de booking sem o extra (go_router não
    // serializa objetos).
    router.go('/booking/flow');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum serviço disponível no momento.'), findsOneWidget);
  });

  testWidgets('booking flow stays alive across internal steps (no extra needed after entry)', (tester) async {
    final bookingRepository = MockBookingRepository();
    when(() => bookingRepository.getAvailableSlots(
          serviceId: any(named: 'serviceId'),
          date: any(named: 'date'),
          barberId: any(named: 'barberId'),
        )).thenAnswer((_) async => const Right([TimeSlot(startTime: '09:00', endTime: '09:30')]));
    final router = buildRouter(bookingRepository: bookingRepository);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(
      '/booking/flow',
      extra: const Service(id: 's1', name: 'Corte', priceInCents: 4000, durationMinutes: 30),
    );
    await tester.pumpAndSettle();
    expect(find.text('Escolha o barbeiro'), findsOneWidget);

    // Advances internal steps entirely inside the flow widget — no go_router
    // push happens, so there's no `extra`-loss risk (unlike the old
    // multi-route shell this replaced).
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Data e horário'), findsOneWidget);
    expect(find.text('Nenhum serviço disponível no momento.'), findsNothing);
  });

  testWidgets('pix-payment route without a PixPayment extra redirects instead of crashing', (tester) async {
    final loyaltyRepository = MockLoyaltyRepository();
    when(() => loyaltyRepository.getAvailableTiers()).thenAnswer((_) async => const Right(<SubscriptionTierView>[]));
    final router = buildRouter(loyaltyRepository: loyaltyRepository);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Simula restore de processo: go_router não serializa `extra`, então
    // reentrar direto nessa rota (deep link, app morto em background) chega
    // sem o PixPayment.
    router.go('/loyalty/pix-payment');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Planos do clube'), findsOneWidget);
  });
}
