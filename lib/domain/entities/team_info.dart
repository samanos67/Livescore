class TeamInfo {
  final int id;
  final String name;
  final String shortName;
  final String logo;
  final String banner;
  final String jersey;
  final String stadium;
  final String stadiumCapacity;
  final String stadiumLocation;
  final String stadiumImage;
  final String city;
  final String country;
  final String founded;
  final String manager;
  final String description;
  final String website;
  final String twitter;
  final String instagram;
  final String youtube;
  final List<String> colours;

  const TeamInfo({
    required this.id,
    required this.name,
    this.shortName = '',
    required this.logo,
    this.banner = '',
    this.jersey = '',
    this.stadium = '',
    this.stadiumCapacity = '',
    this.stadiumLocation = '',
    this.stadiumImage = '',
    this.city = '',
    this.country = '',
    this.founded = '',
    this.manager = '',
    this.description = '',
    this.website = '',
    this.twitter = '',
    this.instagram = '',
    this.youtube = '',
    this.colours = const [],
  });
}
