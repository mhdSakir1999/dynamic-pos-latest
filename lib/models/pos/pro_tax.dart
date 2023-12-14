import 'package:checkout/extension/extensions.dart';


class ProTax {
  String? taXCODE;
  String? taXDESC;
  double? taXDISPLAYRATE;
  double? taXRATE;
  int? ttXSEQUENCE;
  String? ttXFORMULA;
  bool? ttXTAXINC;
  bool? taXCALONLY;

  ProTax(
      {this.taXCODE,
        this.taXDESC,
        this.taXDISPLAYRATE,
        this.taXRATE,
        this.ttXSEQUENCE,
        this.ttXFORMULA,
        this.ttXTAXINC,this.taXCALONLY});

  ProTax.fromJson(Map<String, dynamic> json) {
    taXCODE = json['taX_CODE'];
    taXDESC = json['taX_DESC'];
    taXDISPLAYRATE = json['taX_DISPLAYRATE']?.toString().parseDouble()??0;
    taXRATE = json['taX_RATE']?.toString().parseDouble()??0;
    ttXSEQUENCE = json['ttX_SEQUENCE']?.toString().parseDouble().toInt();
    ttXFORMULA = json['ttX_FORMULA'];
    ttXTAXINC = json['ttX_TAXINC']?.toString().parseBool()??false;
    taXCALONLY = json['taX_CAL_ONLY']?.toString().parseBool()??false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['taX_CODE'] = this.taXCODE;
    data['taX_DESC'] = this.taXDESC;
    data['taX_DISPLAYRATE'] = this.taXDISPLAYRATE;
    data['taX_RATE'] = this.taXRATE;
    data['ttX_SEQUENCE'] = this.ttXSEQUENCE;
    data['ttX_FORMULA'] = this.ttXFORMULA;
    data['ttX_TAXINC'] = this.ttXTAXINC;
    data['taX_CAL_ONLY'] = this.taXCALONLY;
    return data;
  }
}
