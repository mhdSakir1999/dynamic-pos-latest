class TitleResult {
  List<Titles> titles=<Titles>[];

  TitleResult(this.titles);

  TitleResult.fromJson(Map<String, dynamic> json) {
    if (json['titles'] != null) {
      json['titles'].forEach((v) {
        titles.add(new Titles.fromJson(v));
      });
    }
  }
}

class Titles {
  String? tTCODE;
  String? tTDESC;

  Titles({this.tTCODE, this.tTDESC});

  Titles.fromJson(Map<String, dynamic> json) {
    tTCODE = json['tT_CODE'];
    tTDESC = json['tT_DESC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tT_CODE'] = this.tTCODE;
    data['tT_DESC'] = this.tTDESC;
    return data;
  }
}