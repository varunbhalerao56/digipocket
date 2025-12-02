import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

part 'data_export_state.dart';

class DataExportCubit extends Cubit<DataExportState> {
  final DataExportRepository dataRepository;
  final MarkdownDataExportRepository markdownDataRepository;

  DataExportCubit({required this.dataRepository, required this.markdownDataRepository}) : super(DataExportInitial());

  /// Export data to Downloads folder as ZIP
  Future<void> exportJsonLocal() async {
    emit(const DataExportLoading('Creating backup...'));
    try {
      final result = await dataRepository.exportToJsonLocal();
      if (result.success) {
        emit(DataExportSuccess(result));
      } else {
        emit(DataExportError(result.message ?? 'Export failed'));
      }
    } catch (e) {
      emit(DataExportError(e.toString()));
    }
  }

  Future<void> exportJsonShare() async {
    emit(const DataExportLoading('Creating backup...'));
    try {
      final result = await dataRepository.exportToJsonShare();
      if (result.success) {
        emit(DataExportSuccess(result));
      } else {
        emit(DataExportError(result.message ?? 'Export failed'));
      }
    } catch (e) {
      emit(DataExportError(e.toString()));
    }
  }

  /// Import data from user-selected ZIP or folder
  Future<void> importJson() async {
    try {
      emit(const DataExportLoading('Selecting import file...'));

      // Let user choose import source
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);

      if (result == null || result.files.isEmpty) {
        emit(DataExportInitial());
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        emit(const DataExportError('Invalid file selected'));
        return;
      }

      emit(const DataExportLoading('Importing data...'));

      final importResult = await dataRepository.importFromJson(filePath);

      if (importResult.success) {
        emit(DataImportSuccess(importResult));
      } else {
        emit(DataExportError(importResult.message ?? 'Import failed'));
      }
    } catch (e) {
      emit(DataExportError('Import failed: $e'));
    }
  }

  Future<void> exportMarkdownLocal() async {
    emit(const DataExportLoading('Creating markdown backup...'));
    try {
      final result = await markdownDataRepository.exportToMarkdownLocal();
      if (result.success) {
        emit(DataExportSuccess(result));
      } else {
        emit(DataExportError(result.message ?? 'Export failed'));
      }
    } catch (e) {
      emit(DataExportError(e.toString()));
    }
  }

  Future<void> exportMarkdownShare() async {
    emit(const DataExportLoading('Creating markdown backup...'));
    try {
      final result = await markdownDataRepository.exportToMarkdownShare();
      if (result.success) {
        emit(DataExportSuccess(result));
      } else {
        emit(DataExportError(result.message ?? 'Export failed'));
      }
    } catch (e) {
      emit(DataExportError(e.toString()));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(DataExportInitial());
  }
}
