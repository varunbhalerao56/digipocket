import 'package:bloc/bloc.dart';
import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:equatable/equatable.dart';

part 'data_export_state.dart';

class DataExportCubit extends Cubit<DataExportState> {
  DataExportCubit() : super(DataExportInitial());
}
