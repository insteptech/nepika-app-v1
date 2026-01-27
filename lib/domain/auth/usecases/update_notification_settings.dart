import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import '../../auth/entities/notification_settings.dart';
import '../../auth/repositories/auth_repository.dart';

@injectable
class UpdateNotificationSettings {
  final AuthRepository repository;

  UpdateNotificationSettings(this.repository);

  Future<Result<NotificationSettings>> call(NotificationSettings settings) async {
    return await repository.updateNotificationSettings(settings);
  }
}
