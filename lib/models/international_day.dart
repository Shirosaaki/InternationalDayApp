class InternationalDay {
  final String id;
  final int month; // 1-12
  final int day; // 1-31
  final String title;
  final String description;
  final String category;

  const InternationalDay({
    required this.id,
    required this.month,
    required this.day,
    required this.title,
    required this.description,
    required this.category,
  });

  String get dateString {
    const months = [
      "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ];
    return "${day} ${months[month - 1]}";
  }
}
