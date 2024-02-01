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
  var _currentPage = 0;

  var begin=DateTime.now();
  var end=DateTime.now();
  var trans_list=Future.value(List<Transaction>.empty());
  var month_in=0;
  var month_out=0;
  var _selList=List<int>.empty(growable: true);
  var _editTransIdx=-1;
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
        title: Text(widget.title),
      ),
      drawer: _gen_drawer(),
      body: _gen_content(),
      bottomNavigationBar: BottomNavigationBar(

          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.list), label: 'List'),

            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Config'),
          ],
          currentIndex: _currentPage,
        onTap:(int index) {
          setState(() {
            _currentPage = index;
          });
        } ,

      ),

      floatingActionButton: _currentPage == 0 ? FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget? _gen_drawer() {
    if (0 == _currentPage) {
      return Drawer(
          child: ListView(
              children: <Widget>[

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
    }else{

      return null;
    }
  }
  Widget _gen_content() {
    if (0 == _currentPage) {
      if (begin == end) {
        begin = DateTime(begin.year, begin.month, 1);
        end = DateTime(begin.month + 1 < 12 ? begin.year : begin.year + 1,
            begin.month + 1 < 12 ? begin.month + 1 : 1, 1);

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
            var tDate=t.transactionDate.toLocal();
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
                  "${time_fmt.format(t.transactionDate.toLocal())} ${t.method} ${t
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

          SizeConfig().init(context);

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat("yyyy/MM").format(begin))

                ,
                onPressed: _onChangeMonth,
              ),
              Text(_selList.isEmpty
                  ? "収入 ${totalIn} 支出 ${totalOut}"
                  : "合計 ${selVal}"),
              SizedBox(height: SizeConfig.blockSizeVertical * 70, child:
              IndexedListView.builder(controller: IndexedScrollController(
                  initialIndex: -1 != _editTransIdx
                      ?  _editTransIdx
                      : list.length-1),
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
    }else if(1==_currentPage){
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

  ///取引追加ボタンを押された
  void _addTransaction() async{
    assert(0==_currentPage);

    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return EditTransaction(null, title: "");
    })).then((value) {

      if(null!=value){
        TransactionUtils.add(value);

        begin=end= value.transactionDate;

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

  void _onChangeMonth()async{
    final selected = await showMonthPicker(
      context: context,
      initialDate: begin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    setState(() {
      begin=end=DateTime.fromMillisecondsSinceEpoch(selected!.millisecondsSinceEpoch);

    });

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
    end=begin;

    setState(() {});
  }
}