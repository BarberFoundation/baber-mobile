import 'package:equatable/equatable.dart';

sealed class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesEvent {}
