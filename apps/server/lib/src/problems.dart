import 'package:domain/domain.dart';
import 'package:mapping/mapping.dart';
import 'package:relic/relic.dart' hide Result;

import 'http.dart';

/// Jedno mesto gde se domenska greška pretvara u HTTP odgovor.
///
/// Server ne piše poruku za korisnika: šalje stabilan `code` i podatke
/// pravila (granicu, dostupnu količinu…), a klijent od njih pravi istu poruku
/// kao kada pravilo proveri sam. `switch` je iscrpan nad zapečaćenom klasom
/// `DomainError`, pa nova greška u domenu ne može da se zaboravi ovde.
Response domainProblem(DomainError error) => problemResponse(problemOf(error));
