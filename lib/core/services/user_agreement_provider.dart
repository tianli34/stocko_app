import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_agreement_service.dart';

final userAgreementServiceProvider = Provider<UserAgreementService>((ref) {
  return UserAgreementService();
});

final userAgreementStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(userAgreementServiceProvider);
  return await service.hasAcceptedAgreement();
});
