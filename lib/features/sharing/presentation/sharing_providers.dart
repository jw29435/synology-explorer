import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../servers/presentation/server_providers.dart';
import '../data/sharing_api.dart';
import '../domain/share_link.dart';

final sharingApiProvider = Provider<SharingApi>(
  (ref) => SharingApi(sessionClient(ref)),
);

final shareLinksProvider = FutureProvider.autoDispose<List<ShareLink>>(
  (ref) => ref.watch(sharingApiProvider).list(),
);
