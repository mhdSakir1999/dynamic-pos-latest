/// Author: [TM.Sakir]

class HedRemarkModel {
  String? rem1;
  String? rem2;
  String? rem3;
  String? rem4;
  String? rem5;

  HedRemarkModel({this.rem1, this.rem2, this.rem3, this.rem4, this.rem5});

  HedRemarkModel fromMap(Map<String, dynamic> json) {
    return HedRemarkModel(
      rem1: json['invreM_REMARKS1'],
      rem2: json['invreM_REMARKS2'],
      rem3: json['invreM_REMARKS3'],
      rem4: json['invreM_REMARKS4'],
      rem5: json['invreM_REMARKS5'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'INVREM_REMARKS1': this.rem1,
      'INVREM_REMARKS2': this.rem2,
      'INVREM_REMARKS3': this.rem3,
      'INVREM_REMARKS4': this.rem4,
      'INVREM_REMARKS5': this.rem5,
    };
  }
}
