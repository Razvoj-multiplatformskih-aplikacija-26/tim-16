import 'json.dart';

final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    this.params = const {},
    this.title,
  });

  factory ProblemDto.fromJson(JsonMap json) => ProblemDto(
    status: json.read<int>('status'),
    code: json.read<String>('code'),
    params: json.readOptional<JsonMap>('params') ?? const {},
    title: json.readOptional<String>('title'),
  );

  factory ProblemDto.unreadable(int status) =>
      ProblemDto(status: status, code: ErrorCodes.unreadableResponse);

  final int status;
  final String code;
  final JsonMap params;
  final String? title;

  JsonMap toJson() => {
    'status': status,
    'code': code,
    if (params.isNotEmpty) 'params': params,
    'title': ?title,
  };

  @override
  String toString() => 'ProblemDto($status $code $params)';
}

abstract final class ErrorCodes {
  static const quantityNotPositive = 'quantity_not_positive';
  static const quantityExceedsStock = 'quantity_exceeds_stock';
  static const priceOutOfRange = 'price_out_of_range';
  static const stockOutOfRange = 'stock_out_of_range';
  static const textLengthInvalid = 'text_length_invalid';
  static const transitionNotAllowed = 'transition_not_allowed';
  static const cancellationNotAllowed = 'cancellation_not_allowed';
  static const notAuthorized = 'not_authorized';
  static const tooManyActiveOrders = 'too_many_active_orders';
  static const mixedProducers = 'mixed_producers';
  static const duplicateProductInOrder = 'duplicate_product_in_order';
  static const emptyOrder = 'empty_order';
  static const productNotFound = 'product_not_found';
  static const orderNotFound = 'order_not_found';
  static const addressRequired = 'address_required';
  static const insufficientStock = 'insufficient_stock';

  static const badRequest = 'bad_request';
  static const routeNotFound = 'not_found';
  static const unsupportedMediaType = 'unsupported_media_type';
  static const payloadTooLarge = 'payload_too_large';
  static const signInRequired = 'sign_in_required';
  static const serverError = 'server_error';

  static const unreadableResponse = 'unreadable_response';
}
