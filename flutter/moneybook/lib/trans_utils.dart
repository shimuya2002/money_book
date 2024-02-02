

import 'package:moneybook/config.dart';
import 'package:moneybook/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';
import 'package:uuid/uuid_util.dart';
import 'package:uuid/uuid.dart';
class TransactionUtils{
  static Future<void> clear() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
  static Future<void> add(Transaction t) async{
    if(useWStorage) {
      final prefs = await SharedPreferences.getInstance();
      var searchTbl = [t.uuid];
      if (prefs.containsKey(t.uuid)) {
        var oldT = Transaction.fromCSV(prefs.getString(t.uuid)!!);
        var oldUtc=oldT.transactionDate.toUtc();
        var oldYMDate = DateTime(
            oldUtc.year, oldUtc.month, 1)
            .millisecondsSinceEpoch.toString();

        if (prefs.containsKey(oldYMDate)) {
          var oldTbl = prefs.getStringList(oldYMDate)!!;
          oldTbl.remove(t.uuid);
          prefs.setStringList(oldYMDate, oldTbl);
        }
      }
      await prefs.setString(t.uuid, t.convToCSV());
      var newUtc=t.transactionDate.toUtc();
      var newYMDate = DateTime(
          newUtc.year, newUtc.month, 1)
          .millisecondsSinceEpoch.toString();

      if (prefs.containsKey(newYMDate)) {
        var tmpTbl = prefs.getStringList(newYMDate)!;
        tmpTbl.add(t.uuid);
        searchTbl = tmpTbl;
      }

      await prefs.setStringList(newYMDate, searchTbl);
    }else{
      assert(false);
    }

  }

  static Future<void> addRange(List<Transaction> tList)async {
    final prefs = await SharedPreferences.getInstance();

    for(var t in tList){
      await prefs.setString(t.uuid, t.convToCSV());

    }
    recreateDateSearchTbl();
  }
  static Future<void> addMethod(String m)async{
    final prefs = await SharedPreferences.getInstance();
    var methods= prefs.getStringList("methods");
    if(null==methods){
      await prefs.setStringList("methods", <String>[m]);
    }else{
      methods.add(m);
      await prefs.setStringList("methods", methods);

    }

  }
  static Future<void> addRangeMethod(List<String> mList)async{
    final prefs = await SharedPreferences.getInstance();

    var methods=prefs.getStringList("methods");
    if(null==methods){
      await prefs.setStringList("methods", mList);
    }else{

      methods.addAll(mList);
      await prefs.setStringList("methods", methods);

    }

  }

  static Future<void> deleteMethod(String m)async{
    final prefs = await SharedPreferences.getInstance();
    var methods=prefs.getStringList("methods");
    if(null!=methods) {
      for(var i in methods){
        var params=i.split(":");
        if(m==params[0]) {
          methods.remove(i);
        }
      }
      await prefs.setStringList("methods", methods);
    }
  }


  static Future<void> addUsage(String u)async{
    final prefs = await SharedPreferences.getInstance();
    var usages=prefs.getStringList("usages");
    if(null==usages){
      await prefs.setStringList("usages", <String>[u]);
    }else{
        usages.add(u);
      await prefs.setStringList("usages", usages);

    }
  }
  static Future<void> addRangeUsage(List<String> uList)async {
    final prefs = await SharedPreferences.getInstance();
    var usages=prefs.getStringList("usages");
    if(null==usages){
      await prefs.setStringList("usages", uList);
    }else{
      usages.addAll(uList);
      await prefs.setStringList("usages", usages);

    }
  }
  static Future<void> deleteUsage(String u)async{
    final prefs = await SharedPreferences.getInstance();
    var usages=prefs.getStringList("usages");
    if(null!=usages) {
      for(var i in usages){
        if(u==i) {
          usages.remove(i);
        }
      }
      await prefs.setStringList("usages", usages);
    }
  }
  static Future<void> delete(Transaction t)async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(t.uuid);

    var utcDate=t.transactionDate.toUtc();
    var ymDate=DateTime(utcDate.year,utcDate.month,1).millisecondsSinceEpoch.toString();
    if(prefs.containsKey(ymDate)){
      var searchTbl=prefs.getStringList(ymDate)!!;
      searchTbl.remove(t.uuid);
      prefs.setStringList(ymDate, searchTbl);
    }
  }
  static Future<List<String>> getMethods()async{
    final prefs = await SharedPreferences.getInstance();
    var methods= prefs.getStringList("methods");
    if(null!=methods){
      methods.sort();
      return methods;
    }
    return Future.value(List.empty());

  }

  static Future<List<String>> getUsages()async{
    final prefs = await SharedPreferences.getInstance();
    var usages=prefs.getStringList("usages");
    if(null!=usages){
      usages.sort();
      return usages;
    }
    return Future.value(List.empty());
  }

  static Future<List<Transaction>> getAllData()async{
    final prefs = await SharedPreferences.getInstance();
    var result=List<Transaction>.empty(growable: true);

    for(var k in prefs.getKeys()){
      if("methods"!=k && "usages"!=k && Uuid.isValidUUID(fromString: k)){

        result.add(Transaction.fromCSV(prefs.getString(k)!!));
      }

    }

    result.sort((a,b)=>a.transactionDate.compareTo(b.transactionDate) );



    return Future<List<Transaction>>.value(result);
  }

  static Future<void>recreateDateSearchTbl()async{
    final prefs = await SharedPreferences.getInstance();


    for(var k in prefs.getKeys()){
      if("methods"!=k && "usages"!=k && !Uuid.isValidUUID(fromString: k)){
        prefs.remove(k);

      }


    }


    for(var k in prefs.getKeys()){
      if("methods"!=k && "usages"!=k ){
        var t=Transaction.fromCSV(prefs.getString(k)!!);
        var utcDate=t.transactionDate.toUtc();
        var yMDate=DateTime(utcDate.year,utcDate.month,1).millisecondsSinceEpoch.toString();
        var l=[t.uuid];
        if(prefs.containsKey(yMDate)){
          var tmp=prefs.getStringList(yMDate)!!;
          tmp.addAll(l);
          l=tmp;
        }
        prefs.setStringList(yMDate, l);
      }


    }


  }
  ///
  /// b<= && e>の範囲の取引を取得する
  static Future<List<Transaction>> getData(DateTime b,DateTime e) async{



    final prefs = await SharedPreferences.getInstance();
    var result=List<Transaction>.empty(growable: true);
    var bUTC=b.toUtc();
    var eUTC=e.toUtc();
    var tmpYMDate=DateTime(bUTC.year,bUTC.month,1);
    do{
      var keyStr=tmpYMDate.millisecondsSinceEpoch.toString();

      if(prefs.containsKey(keyStr)){
        var searchTbl=prefs.getStringList(keyStr)!!;

        if(0<searchTbl.length) {
          for (var id in searchTbl) {

            var t = Transaction.fromCSV(prefs.getString(id)!);
            if (0 <= t.transactionDate.compareTo(b) &&
                0 > t.transactionDate.compareTo(e)) {
              result.add(t);

            }
          }
        }
      }

      tmpYMDate=DateTime(12==tmpYMDate.month?tmpYMDate.year+1: tmpYMDate.year,
          12==tmpYMDate.month?1: tmpYMDate.month+1,1);


    }while(0>tmpYMDate.compareTo(eUTC));


    result.sort((a,b)=>a.transactionDate.compareTo(b.transactionDate) );
    return Future<List<Transaction>>.value(result);
  }
  static Future<String> convToCSV() async{
    var result="";
    for(var t in (await getAllData())){
      result+=t.convToCSV()+"\n";
    }

    return Future.value(result);
  }


}