


import 'package:uuid/uuid.dart';
abstract class Currency{

  static Currency parse(String t){
    if("￥"==t[0]){
      return JPY(int.parse(t.substring(1)));
    }else{
      return JPY(int.parse(t));
    }
  }
  static Currency gen(double v){
    return JPY(v.toInt());
  }

  Currency abs();
  Currency neg();
  int comp(int v);
  int toInt();
}
class JPY extends Currency {

  int value = 0;

  JPY(this.value);

  @override
  String toString() {
    return "￥${value}";
  }
  Currency abs(){

    return JPY(value.abs());

  }
  Currency neg(){
    return JPY(-value);
  }
  int comp(int v){
    return value-v;
  }
  int toInt(){
    return value;
  }
}
///取引を記述するクラス
class Transaction{
  String uuid;    ///DB内で使用するkey
  DateTime transactionDate=DateTime.now();/*!取引日付*/
  String method="";///支払い方法
  String usage="";///使途
  Currency value=Currency.gen(0);  ///金額
  String note="";///備考　購入品の記載等に使用



  ///
  /// コンストラクタ
  /// パラメータ詳細はメンバを参照
  Transaction(this.uuid,this.transactionDate,this.method,this.usage,this.value,this.note);

  Transaction.fromMap(Map<dynamic,dynamic> m)
      :this(
        m["uuid"]as String,
        DateTime.fromMillisecondsSinceEpoch(m["transactionDate"] as int),
        m["method"] as String,
        m["usage"] as String,
        Currency.gen(m["value"] as double),
        m["note"] as String);


  static Transaction Dummy(){
    return Transaction(Uuid().v1(), DateTime.now(), "","", Currency.gen(0), "");
  }

  Transaction clone(){
    return Transaction(Uuid().v1(), this.transactionDate, method, usage, value, note);
  }
  ///
  /// csv形式の文字列からオブジェクトを復元
  static Transaction fromCSV(String csv){
    var params=csv.split(",");
    return Transaction(params[0], DateTime.parse(params[1]), params[2], params[3], Currency.parse(params[4]), params[5]);
  }



  ///
  /// 自身をcsv形式の文字列へ変換
  String convToCSV(){

      return "$uuid,${transactionDate
          .toIso8601String()},$method,$usage,$value,$note";

  }



  ///
  /// Sqliteへ入力するためのデータを作成する
  Map<String,dynamic> toMap(){
   return {
     "uuid":uuid,
     "transactionDate":transactionDate.millisecondsSinceEpoch,
     "method":method,
     "usage":usage,
     "value":value,
     "note":note
   };
  }
  DateTime getSearchTblDateTime(){
    return DateTime(transactionDate.year,transactionDate.month,1);
  }
}
class MethodUsageValue {
  String key;
  bool show;
  int planValue;

  MethodUsageValue(this.key, this.show, this.planValue);

  MethodUsageValue.fromMap(Map<dynamic, dynamic> m)
      :this(m["key"] as String, m["show"] as bool, m["planValue"] as int);

  String toCSV() {
    return "$key,$show,$planValue";
  }

  Map<String, dynamic> toMap() {
    return {
      "key": key,
      "show": show,
      "planValue": planValue
    };
  }

  static MethodUsageValue fromCSV(String csv) {
    var params = csv.split(",");
    return MethodUsageValue(
        params[0], bool.parse(params[1]), int.parse(params[2]));
  }


}