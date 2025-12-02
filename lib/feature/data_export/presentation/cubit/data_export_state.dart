part of 'data_export_cubit.dart';

abstract class DataExportState extends Equatable {
  const DataExportState();

  @override
  List<Object?> get props => [];
}

class DataExportInitial extends DataExportState {}

class DataExportLoading extends DataExportState {
  final String message;

  const DataExportLoading(this.message);

  @override
  List<Object?> get props => [message];
}

class DataExportSuccess extends DataExportState {
  final ExportResult result;

  const DataExportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class DataImportSuccess extends DataExportState {
  final ImportResult result;

  const DataImportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class DataExportError extends DataExportState {
  final String error;

  const DataExportError(this.error);

  @override
  List<Object?> get props => [error];
}
