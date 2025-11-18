import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'user_topic_state.dart';

class UserTopicsCubit extends Cubit<UserTopicState> {
  UserTopicsCubit() : super(UserTopicInitial());
}
