/// What an error must expose for `SrErrorState` to explain it: 0 is offline,
/// 402 a plan quota, 403 forbidden, 404 not found.
abstract interface class SrDisplayableFailure {
  int get statusCode;
  String get message;
}
