import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'baber_app.dart';
import 'core/api/api_client.dart';
import 'core/auth/token_storage.dart';
import 'core/tenancy/tenant_storage.dart';
import 'features/appointments/data/appointment_repository_impl.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/booking/data/booking_repository_impl.dart';
import 'features/catalog/data/service_repository_impl.dart';
import 'features/tenant_selection/data/tenant_repository_impl.dart';

void main() {
  const storage = FlutterSecureStorage();
  final tokenStorage = TokenStorage(storage);
  final tenantStorage = TenantStorage(storage);
  // API_BASE_URL is the host only; the backend serves everything (except
  // /health) under the global "api" prefix with URI versioning (v1).
  const apiHost = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
  final apiClient = ApiClient(
    baseUrl: '$apiHost/api/v1',
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
  );
  final authRepository = AuthRepositoryImpl(apiClient.dio, tenantStorage);
  final tenantRepository = TenantRepositoryImpl(apiClient.dio);
  final serviceRepository = ServiceRepositoryImpl(apiClient.dio);
  final bookingRepository = BookingRepositoryImpl(apiClient.dio);
  final appointmentRepository = AppointmentRepositoryImpl(apiClient.dio);

  runApp(BaberApp(
    tokenStorage: tokenStorage,
    tenantStorage: tenantStorage,
    authRepository: authRepository,
    tenantRepository: tenantRepository,
    serviceRepository: serviceRepository,
    bookingRepository: bookingRepository,
    appointmentRepository: appointmentRepository,
    dio: apiClient.dio,
    appLinks: AppLinks(),
  ));
}
