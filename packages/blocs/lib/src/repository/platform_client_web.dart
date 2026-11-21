import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Pregledač: prijava u httpOnly kolačiću, koji JavaScript ne vidi;
/// pregledač ga sam šalje uz svaki zahtev.
const platformKeepsSessionInCookie = true;

http.Client platformHttpClient() => BrowserClient()..withCredentials = true;