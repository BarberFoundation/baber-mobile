import 'package:equatable/equatable.dart';
import '../domain/service.dart';

class ServicesState extends Equatable {
  final List<Service>? services;
  final String? errorMessage;
  final bool isLoading;

  const ServicesState({this.services, this.errorMessage, this.isLoading = false});

  const ServicesState.initial() : this();
  const ServicesState.loading() : this(isLoading: true);
  const ServicesState.loaded(List<Service> services) : this(services: services);
  const ServicesState.error(String message) : this(errorMessage: message);

  @override
  List<Object?> get props => [services, errorMessage, isLoading];
}
