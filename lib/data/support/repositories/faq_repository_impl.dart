import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/error/exceptions.dart';
import '../../../domain/support/entities/faq.dart';
import '../../../domain/support/repositories/faq_repository.dart';
import '../datasources/faq_remote_data_source.dart';

class FaqRepositoryImpl implements FaqRepository {
  final FaqRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FaqRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Faq>>> getFaqs({String? targetAudience}) async {
    if (await networkInfo.isConnected) {
      try {
        final faqs = await remoteDataSource.getFaqs(targetAudience: targetAudience);
        // Sort by display order
        faqs.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return Right(faqs);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
