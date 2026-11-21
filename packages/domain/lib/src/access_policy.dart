import 'user.dart';

/// Ko sme u koju aplikaciju. Na jednom mestu u domenu: SessionBloc ga
/// koristi da odbije prijavu u pogrešnoj aplikaciji, a server po ulozi
/// odbija svaku akciju koja nije za tu ulogu.
bool canUseMobileApp(User user) => user.role == UserRole.buyer;

bool canUseBackoffice(User user) => user.role == UserRole.producer;