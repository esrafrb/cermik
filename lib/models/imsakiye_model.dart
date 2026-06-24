class ImsakiyeModel {
  final int id;
  final int districtId;
  final DateTime date;
  final String? dayTitle;
  final String? imsak;
  final String? iftar;
  final int bayramDay;
  final String? bayramNamazi;
  final String? imageUrl;

  ImsakiyeModel({
    required this.id,
    required this.districtId,
    required this.date,
    this.dayTitle,
    this.imsak,
    this.iftar,
    required this.bayramDay,
    this.bayramNamazi,
    this.imageUrl,
  });

  factory ImsakiyeModel.fromJson(Map<String, dynamic> json) {
    return ImsakiyeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      districtId: int.tryParse(json['district_id'].toString()) ?? 0,
      date: DateTime.parse(json['date']),
      dayTitle: json['day_title'],
      imsak: json['imsak'],
      iftar: json['iftar'],
      bayramDay: int.tryParse(json['is_bayram'].toString()) ?? 0,
      bayramNamazi: json['bayram_namazi'],
      imageUrl: json['image_url'],
    );
  }
}
