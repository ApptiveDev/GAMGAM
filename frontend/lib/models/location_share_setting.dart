enum LocationShareLevel { off, basic, closeFriends }

class LocationShareSetting {
  const LocationShareSetting({required this.level, required this.title, required this.description});

  final LocationShareLevel level;
  final String title;
  final String description;
}
