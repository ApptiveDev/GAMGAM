enum PokeMessage { hurryUp, waitForYou, runningLate, takeYourTime }

class PokeNotification {
  const PokeNotification({
    required this.senderName,
    required this.message,
    required this.cooldownMinutes,
  });

  final String senderName;
  final PokeMessage message;
  final int cooldownMinutes;
}
