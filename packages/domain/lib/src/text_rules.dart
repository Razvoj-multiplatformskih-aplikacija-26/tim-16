import 'package:domain/src/result.dart';

import 'errors.dart';

Result<String>parseBoundedText(
String raw,{
  required TextKind kind,
required int min,
required int max,
}
){
  final text=raw.trim();
  if(text.length<min||text.length>max)
    {
      return Failure<String>(
        TextLengthInvalid(kind: kind,length:text.length,min:min,max:max),
      );
    }
  return Success<String>(text);
}