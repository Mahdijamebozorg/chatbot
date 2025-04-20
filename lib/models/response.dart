class Response {
  final List<String> triggers;
  final String text;
  final List<String> buttons;
  final String? followUp;

  Response({
    required this.triggers,
    required this.text,
    this.buttons = const [],
    this.followUp,
  });
}
