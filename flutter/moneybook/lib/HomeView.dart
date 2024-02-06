import 'dart:collection';

import 'package:moneybook/trans_utils.dart';
import 'package:moneybook/transaction.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:moneybook/edit_transaction.dart';
import 'package:intl/intl.dart';
import 'package:flutter_month_picker/flutter_month_picker.dart';
import 'package:moneybook/import_file_view.dart';
import 'package:moneybook/size_config.dart';
import 'package:indexed_list_view/indexed_list_view.dart';
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.title});
  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}
class _HomeViewState extends State<HomeView> {
  static const PAGE_LIST=0;
  static const PAGE_SEARCH=PAGE_LIST+1;
  static const PAGE_CONFIG=PAGE_SEARCH+1;
  static const SHOW_LIST_DATA=0;
  static const SHOW_CHART_DATA=SHOW_LIST_DATA+1;
  static const SEARCH_RANGE_SET=0;
  static const SEARCH_RESULT_SHOW=SEARCH_RANGE_SET+1;
  var _currentPage = PAGE_LIST;
  var _showDataMode=SHOW_LIST_DATA;
  var begin=DateTime.now();
  var end=DateTime.now();
  var trans_list=Future.value(List<Transaction>.empty());
  var month_in=0;
  var month_out=0;
  var _selList=List<int>.empty(growable: true);
  var _editTransIdx=-1;
  var _chartMode=0;
  var _searchMode=SEARCH_RANGE_SET;





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: _gen_title(),
      ),
      drawer: _gen_drawer(),
      body: _gen_content(),
      bottomNavigationBar:BottomNavigationBar(

          items: const [
            BottomNavigationBarItem(
                icon:Icon(Icons.list), label: 'List'),

            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Config'),
          ],
          currentIndex: _currentPage,
        type: BottomNavigationBarType.fixed,
        onTap:(int index) {
          setState(() {
            if(PAGE_LIST== _currentPage && PAGE_SEARCH==index){
              end=begin;
            }

            _currentPage = index;
          });
        } ,

      ),

      floatingActionButton: _currentPage == 0 ? FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  Widget? _gen_title(){
    if (begin == end) {
      begin = DateTime(begin.year, begin.month, 1).toLocal();
      end = DateTime(begin.month + 1 <= 12 ? begin.year : begin.year + 1,
          begin.month + 1 <= 12 ? begin.month + 1 : 1, 1).toLocal();
      if(PAGE_SEARCH==_currentPage && SEARCH_RANGE_SET==_searchMode)
      {
        end=end.subtract(Duration(days: 1));
      }


    }
    final dataModeCaptions = ["List", "Chart"];
    final modeDropdown = DropdownButton<String>(
        value: dataModeCaptions[_showDataMode],
        items: dataModeCaptions.map<DropdownMenuItem<String>>(
                (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (null != newValue) {
              _showDataMode = dataModeCaptions.indexOf(newValue);
            }
          });
        }

    );
    if(PAGE_LIST==_currentPage ) {




      return Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(DateFormat("yyyy/MM").format(begin))

            ,
            onPressed: _onChangeMonth,
          ),
          modeDropdown

        ],
      );
    }else if(PAGE_SEARCH==_currentPage) {
      if (SEARCH_RESULT_SHOW == _searchMode) {
        return Row(
          children: [

            modeDropdown

          ],
        );
      } else {
        return Text("Search");
      }
    }
    else{
      return Text("Config");
    }

  }

  Widget? _gen_drawer() {
    if (PAGE_LIST == _currentPage) {
      return Drawer(
          child: ListView(
              children: <Widget>[

                ListTile(
                  title: Text("Deselect"),
                  onTap: (){
                    _onDeselAll();
                    Navigator.of(context).pop();

                  },
                ),
                ListTile(
                  title: Text('Copy'),
                  onTap:(){
                    _onCopy();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('Delete'),
                  onTap:(){
                    _onDelete();
                    Navigator.of(context).pop();

                  },
                ),
              ]));
    }else if(PAGE_SEARCH==_currentPage && SEARCH_RESULT_SHOW==_searchMode) {
      return Drawer(
          child: ListView(
              children: <Widget>[

                ListTile(
                  title: Text("Reset"),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _searchMode = SEARCH_RANGE_SET;

                    });
                  },
                ),
              ]));
    } else{

      return null;
    }
  }
  Widget _gen_content() {
    SizeConfig().init(context);
    if (PAGE_LIST == _currentPage) {
 /*     if (begin == end) {
        begin = DateTime(begin.year, begin.month, 1).toLocal();
        end = DateTime(begin.month + 1 < 12 ? begin.year : begin.year + 1,
            begin.month + 1 < 12 ? begin.month + 1 : 1, 1).toLocal();

        trans_list = TransactionUtils.getData(begin, end);
      }

      return FutureBuilder(
          future: trans_list, builder:
          (BuildContext context,
          AsyncSnapshot<List<Transaction>> snapshot) {
        if (snapshot.hasData) {
          final time_fmt = DateFormat("HH:mm");
          final date_fmt = DateFormat("yyyy/MM/dd");
          var list = List<Widget>.empty(growable: true);
          var totalIn = 0;
          var totalOut = 0;
          var dailyIn = 0;
          var dailyOut = 0;

          var selVal = 0;
          var tmp = List<ListTile>.empty(growable: true);
          var curDate = DateTime.fromMillisecondsSinceEpoch(0).toLocal();
          for (var i = 0; i < snapshot.data!.length; ++i) {
            var t = snapshot.data![i];
            if (_selList.contains(i)) {
              selVal += t.value.toInt();
            }
            var tDate = t.transactionDate.toLocal();
            if (curDate.year != tDate.year ||
                curDate.month != tDate.month ||
                curDate.day != tDate.day) {
              if (tmp.isNotEmpty) {
                list.add(
                    ListTile(
                        tileColor: Colors.grey, textColor: Colors.white,
                        title: Text("${date_fmt.format(
                            curDate)} 収入 ${dailyIn} 支出 ${dailyOut}")));
                list.addAll(tmp);
                tmp.clear();
              }
              curDate = t.transactionDate.toLocal();
              dailyIn = dailyOut = 0;
            }
            tmp.add(ListTile(textColor: Colors.black,
              tileColor: _selList.contains(i) ? Colors.blue : Colors.white,
              title: Text(
                  "${time_fmt.format(t.transactionDate.toLocal())} ${t
                      .method} ${t
                      .usage} ${t.note} ${t.value}"),

              onTap: () {
                _editTransaction(i);
              },
              onLongPress: () {
                _onSelDeselTrans(i);
              },
            ));
            if (0 < t.value.comp(0)) {
              totalIn += t.value.toInt();
              dailyIn += t.value.toInt();
            } else {
              totalOut += t.value.abs().toInt();
              dailyOut += t.value.abs().toInt();
            }
          }
          if (tmp.isNotEmpty) {
            list.add(
                ListTile(tileColor: Colors.grey, textColor: Colors.white,
                    title: Text("${date_fmt.format(
                        curDate)} 収入 ${dailyIn} 支出 ${dailyOut}")));
            list.addAll(tmp);
            tmp.clear();
          }


          final dataModeCaptions=["List","Chart"];

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             /* ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat("yyyy/MM").format(begin))

                ,
                onPressed: _onChangeMonth,
              ),*/
              DropdownButton<String>(
                  value: dataModeCaptions[_showDataMode],
                  items: dataModeCaptions.map<DropdownMenuItem<String>>(
                          (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      if (null != newValue) {
                        _showDataMode = dataModeCaptions.indexOf(newValue);
                      }
                    });
                  }

              ),
              Text(_selList.isEmpty
                  ? "収入 ${totalIn} 支出 ${totalOut}"
                  : "合計 ${selVal}"),
              SizedBox(height: SizeConfig.blockSizeVertical * 70, child:
              IndexedListView.builder(controller: IndexedScrollController(
                  initialIndex: -1 != _editTransIdx
                      ? _editTransIdx
                      : list.length - 1),
                  minItemCount: 0,
                  maxItemCount: list.length - 1,
                  itemBuilder: (context, index) {
                    return list[index];
                  }))

              //ListView(children: list)),
            ],
          );
        } else {
          return ListView();
        }
      }
      );*/
      return _gen_data_view();
    }else if(PAGE_SEARCH==_currentPage) {
      if(SEARCH_RANGE_SET==_searchMode){
        return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Begin date"),
                    ElevatedButton(
                        child: Text(DateFormat("yyyy/MM/dd").format(begin)),
                        onPressed:_onChangeBeginDate
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("End date"),
                    ElevatedButton(
                        child: Text(DateFormat("yyyy/MM/dd").format(end)),
                        onPressed:_onChangeEndDate
                    ),
                  ],
                ),
                ElevatedButton(
                    child: Text("Search"),
                    onPressed:_onSearch
                ),


              ],
            )
        );

      }else{
        return _gen_data_view();

      }
    } else if(PAGE_CONFIG==_currentPage){
      end=begin;
      return ListView(
        children: [


            ListTile(
              title: Row(children: [Icon(Icons.upload_file),Text("Import from file")],

            ),
          onTap: _onImportFile
          ,),
          ListTile(
            title: Row(children: [Icon(Icons.file_download_done_sharp),Text("Export to file")],

            ),
            onTap: _onExportFile
            ,),
          ListTile(
            title: Row(children: [Icon(Icons.clear),Text("Clear all data")],

            ),
            onTap: _onClearData
            ,)
        ],
      );
    }else{
      return const Spacer();
    }
  }
  Widget _gen_data_view(){
    SizeConfig().init(context);

    trans_list = TransactionUtils.getData(begin, end);
    /*final dataModeCaptions=["List","Chart"];

    final modeDropdown=DropdownButton<String>(
        value: dataModeCaptions[_showDataMode],
        items: dataModeCaptions.map<DropdownMenuItem<String>>(
                (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (null != newValue) {
              _showDataMode = dataModeCaptions.indexOf(newValue);
            }
          });
        }

    );*/
    if(SHOW_LIST_DATA==_showDataMode || (PAGE_SEARCH==_currentPage && SEARCH_RESULT_SHOW==_searchMode)){
      return FutureBuilder(
          future: trans_list, builder:
          (BuildContext context,
          AsyncSnapshot<List<Transaction>> snapshot) {
        if (snapshot.hasData) {
          final time_fmt = DateFormat("HH:mm");
          final date_fmt = DateFormat("yyyy/MM/dd");
          var list = List<Widget>.empty(growable: true);
          var totalIn = 0;
          var totalOut = 0;
          var dailyIn = 0;
          var dailyOut = 0;

          var selVal = 0;
          var tmp = List<ListTile>.empty(growable: true);
          var curDate = DateTime.fromMillisecondsSinceEpoch(0).toLocal();
          for (var i = 0; i < snapshot.data!.length; ++i) {
            var t = snapshot.data![i];
            if (_selList.contains(i)) {
              selVal += t.value.toInt();
            }
            var tDate = t.transactionDate.toLocal();
            if (curDate.year != tDate.year ||
                curDate.month != tDate.month ||
                curDate.day != tDate.day) {
              if (tmp.isNotEmpty) {
                list.add(
                    ListTile(
                        tileColor: Colors.grey, textColor: Colors.white,
                        title: Text("${date_fmt.format(
                            curDate)} 収入 ${dailyIn} 支出 ${dailyOut}")));
                list.addAll(tmp);
                tmp.clear();
              }
              curDate = t.transactionDate.toLocal();
              dailyIn = dailyOut = 0;
            }
            tmp.add(ListTile(textColor: Colors.black,
              tileColor: _selList.contains(i) ? Colors.blue : Colors.white,
              title: Text(
                  "${time_fmt.format(t.transactionDate.toLocal())} ${t
                      .method} ${t
                      .usage} ${t.note} ${t.value}"),

              onTap: () {
                _editTransaction(i);
              },
              onLongPress: () {
                _onSelDeselTrans(i);
              },
            ));
            if (0 < t.value.comp(0)) {
              totalIn += t.value.toInt();
              dailyIn += t.value.toInt();
            } else {
              totalOut += t.value.abs().toInt();
              dailyOut += t.value.abs().toInt();
            }
          }
          if (tmp.isNotEmpty) {
            list.add(
                ListTile(tileColor: Colors.grey, textColor: Colors.white,
                    title: Text("${date_fmt.format(
                        curDate)} 収入 ${dailyIn} 支出 ${dailyOut}")));
            list.addAll(tmp);
            tmp.clear();
          }



          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat("yyyy/MM").format(begin))

                ,
                onPressed: _onChangeMonth,
              ),*/
             //modeDropdown,
              Text(_selList.isEmpty
                  ? "収入 ${totalIn} 支出 ${totalOut}"
                  : "合計 ${selVal}"),
              SizedBox(height: SizeConfig.blockSizeVertical * 70, child:
              IndexedListView.builder(controller: IndexedScrollController(
                  initialIndex: -1 != _editTransIdx
                      ? _editTransIdx
                      : list.length - 1),
                  minItemCount: 0,
                  maxItemCount: list.length - 1,
                  itemBuilder: (context, index) {
                    return list[index];
                  }))

              //ListView(children: list)),
            ],
          );
        } else {
          return ListView();
        }
      }
      );
    }else{
      final modeCaption = ["Methods", "Usages"];
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //modeDropdown,
          DropdownButton<String>(
              value: modeCaption[_chartMode],
              items: modeCaption.map<DropdownMenuItem<String>>(
                      (String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  if (null != newValue) {
                    _chartMode = modeCaption.indexOf(newValue);
                  }
                });
              }

          ),
          FutureBuilder(future: trans_list, builder: (BuildContext context,
              AsyncSnapshot<List<Transaction>> snapshot) {
            if (snapshot.hasData) {
              var chartTbl = HashMap<String, Currency>();
              for (var t in snapshot.data!) {
                var c = t.value;
                if (0 == _chartMode) {
                  if (chartTbl.containsKey(t.method)) {
                    c = c.add(chartTbl[ t.method]!);
                  }
                  chartTbl[t.method] = c;
                } else {
                  if (chartTbl.containsKey(t.usage)) {
                    c = c.add(chartTbl[ t.usage]!);
                  }
                  chartTbl[t.usage] = c;
                }
              }


              return SizedBox(height: SizeConfig.blockSizeVertical * 70, child:

              ListView.builder(
                  itemCount: chartTbl.length,
                  itemBuilder: (BuildContext context, int index) {
                    var k = chartTbl.keys.elementAt(index);
                    return ListTile(
                      title: Text("${k} ${chartTbl[k]}"),
                    );
                  }));
            } else {
              return  SizedBox(height: SizeConfig.blockSizeVertical * 70, child:ListView());
            }
          })
        ],
      );
    }
  }

  ///取引追加ボタンを押された
  void _addTransaction() async{
    assert(0==_currentPage);

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return EditTransaction(null, title: "");
    })).then((value) {

      if(null!=value){
        TransactionUtils.add(value);

        begin=end= (value.transactionDate).toLocal();

      }


    });
    setState(() {

    });
  }

  void _editTransaction(int i) async{
    assert(0==_currentPage);

    var t=(await trans_list)[i];
    _editTransIdx=i;

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return EditTransaction(t, title: "");
    })).then((value) {

      if(null!=value){
        TransactionUtils.add(value);

        begin=end= value.transactionDate;

      }


    });
    setState(() {

    });
  }
  void _onChangeBeginDate()async{
    final selected=await showDatePicker(
        context: context,
        initialDate: begin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if(null!=selected){
      setState((){
        begin=selected!;
      }
      );
    }
  }

  void _onChangeEndDate()async{
    final selected=await showDatePicker(
      context: context,
      initialDate: begin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if(null!=selected){
      setState((){
        end=selected!;
      }
      );
    }
  }

  void _onChangeMonth()async{
    final selected = await showMonthPicker(
      context: context,
      initialDate: begin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if(null!=selected){
      setState(() {
        begin=end=DateTime.fromMillisecondsSinceEpoch(selected!.millisecondsSinceEpoch);

      });

    }

  }
  void _onImportFile()async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ImportExportFileView(true, title: "");
    }));

  }

  void _onExportFile()async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ImportExportFileView(false, title: "");
    }));

  }
  void _onClearData()async{
    await TransactionUtils.clear();

  }
  void _onSelDeselTrans(int i)async {
    //_editTransIdx=((await trans_list).length-1)>i+1?i+1:i;
    setState(() {
      if(_selList.contains(i)){
        _selList.remove(i);
      }else{
        _selList.add(i);
        _selList.sort();
      }


    });
  }
  void _onSearch(){

    setState(() {
      end=end.add(Duration(days:1));
      _searchMode=SEARCH_RESULT_SHOW;

    });

  }
  void _onDeselAll(){
    setState(() {
      _selList.clear();
    });
  }
  void _onCopy() async{
    var list=await trans_list;
    for(var i in _selList){
      var t=list[i];
      TransactionUtils.add(t.clone());
    }
    _selList.clear();
    end=begin;

    setState(() {});
  }
  void _onDelete()async {
    var list=await trans_list;
    for(var i in _selList){
      var t=list[i];
      TransactionUtils.delete(t);
    }
    _selList.clear();
    end=begin;

    setState(() {});
  }
}