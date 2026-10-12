class Player {
  final int id;
  final String name;
  final String photo;
  final String position;
  final String nationality;
  final String birthDate;
  final String number;
  final String height;
  final String weight;
  final String description;

  const Player({
    required this.id,
    required this.name,
    this.photo = '',
    this.position = '',
    this.nationality = '',
    this.birthDate = '',
    this.number = '',
    this.height = '',
    this.weight = '',
    this.description = '',
  });

  /// Approximate age from birth date string (yyyy-MM-dd or yyyy-MM-ddThh...)
  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      final birth = DateTime.parse(birthDate.substring(0, 10));
      final now   = DateTime.now();
      int age     = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }
}
