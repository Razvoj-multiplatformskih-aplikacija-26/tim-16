import 'package:http/http.dart' as http;

/// Telefon i desktop: token u zaglavlju Authorization.
const platformKeepsSessionInCookie = false;

http.Client platformHttpClient() => http.Client();