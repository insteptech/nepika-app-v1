import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import '../../auth/entities/notification_settings.dart';
import '../../auth/repositories/auth_repository.dart';

@injectable
class GetNotificationSettings {
  final AuthRepository repository;

  GetNotificationSettings(this.repository);

  Future<Result<NotificationSettings>> call() async {
    return await repository.getNotificationSettings();
  }
}
