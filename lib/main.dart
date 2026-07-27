import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'baber_app.dart';
import 'core/api/api_client.dart';
import 'core/auth/token_storage.dart';
import 'core/config/base_url_guard.dart';
import 'core/firebase/firebase_auth_gateway.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/appointments/data/appointment_repository_impl.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/booking/data/booking_repository_impl.dart';
import 'features/catalog/data/service_repository_impl.dart';
import 'features/loyalty/data/loyalty_repository_impl.dart';
import 'features/notifications/data/notifications_repository_impl.dart';
import 'features/profile/data/profile_repository_impl.dart';
import 'features/tenant_selection/data/tenant_repository_impl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const storage = FlutterSecureStorage();
  final tokenStorage = TokenStorage(storage);
  final tenantStorage = TenantStorage(storage);
  // API_BASE_URL is the host only; the backend serves everything (except
  // /health) under the global "api" prefix with URI versioning (v1).
  const apiHost = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
  assertSecureBaseUrl(apiHost, isRelease: kReleaseMode);
  final apiClient = ApiClient(
    baseUrl: '$apiHost/api/v1',
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
  );
  // iOS/macOS google_sign_in reads its client ID from GoogleService-Info.plist —
  // this project has none (Firebase itself is configured purely through
  // firebase_options.dart), so GIDSignIn has no client ID and signIn() crashes
  // natively. Pass it explicitly from the same FlutterFire-generated options.
  // Android is unaffected: it resolves its client ID from google-services.json.
  final googleSignIn = GoogleSignIn(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
  );
  final firebaseAuthGateway = FirebaseAuthGatewayImpl(FirebaseAuth.instance, googleSignIn);
  final authRepository = AuthRepositoryImpl(firebaseAuthGateway, apiClient.dio, tenantStorage);
  final tenantRepository = TenantRepositoryImpl(apiClient.dio);
  final serviceRepository = ServiceRepositoryImpl(apiClient.dio);
  final bookingRepository = BookingRepositoryImpl(apiClient.dio);
  final loyaltyRepository = LoyaltyRepositoryImpl(apiClient.dio);
  final appointmentRepository = AppointmentRepositoryImpl(apiClient.dio);
  final notificationsRepository = NotificationsRepositoryImpl(apiClient.dio);
  final profileRepository = ProfileRepositoryImpl(apiClient.dio);

  runApp(BaberApp(
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
    authRepository: authRepository,
    tenantRepository: tenantRepository,
    serviceRepository: serviceRepository,
    bookingRepository: bookingRepository,
    loyaltyRepository: loyaltyRepository,
    appointmentRepository: appointmentRepository,
    notificationsRepository: notificationsRepository,
    profileRepository: profileRepository,
    appLinks: AppLinks(),
  ));
}
