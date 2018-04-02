import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:side_header_list_view/side_header_list_view.dart';

void main() => runApp(new DaysApp());

enum MealDayType { breakfast, lunch, dinner, snack, candy }

class DaysApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Days',
      theme: new ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: new MyDaysWG(title: 'My Days'),
    );
  }
}

class MyDaysWG extends StatefulWidget {
  MyDaysWG({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyDaysState createState() => new _MyDaysState();
}

class _MyDaysState extends State<MyDaysWG> with SingleTickerProviderStateMixin {
  var _items = new List<DayItem>();
  var _loadingInProgress = false;
  TabController _tabMealController;

  @override
  initState() {
    super.initState();
    setState(() {
      _loadingInProgress = true;
    });
    _tabMealController = new TabController(length: MealDayType.values.length, vsync: this);
    _getItemsFromStorage().then((items) => _didLoadItems(items));
  }

  _didLoadItems(List<DayItem> items) {
    setState(() {
      _items = items;
      _loadingInProgress = false;
    });
  }

  void _addItem(DayItem item) {
    setState(() {
      _items.insert(0,item);
      _setItemsToStorage(_items);
    });
  }

  void _removeItem(DayItem item) {
    setState(() {
      _items.remove(item);
      _setItemsToStorage(_items);
    });
  }

  _setItemsToStorage(List<DayItem> items) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final itemsString = items.map((i) => json.encode(i)).toList();
    print(itemsString);
    prefs.setStringList('day-items', itemsString);
  }

  Future<List<DayItem>> _getItemsFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final itemsStrings = prefs.getStringList('day-items');
    if (itemsStrings == null) return <DayItem>[];
    List<Map> itemsMap = itemsStrings.map((i) => json.decode(i)).toList();
    return itemsMap.map((i) => new DayItem.fromJson(i)).toList();
  }

  void _resetInput() {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  void _scrollToNew() {
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) { return; }
    _resetInput();
    _scrollToNew();
    final mealType = MealDayType.values[_tabMealController.index];
    var item = new DayItem(text, mealType);
    _addItem(item);
  }

  final TextEditingController _textController = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();
  bool _isComposing = false;

  Widget _buildSendButton() {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? new CupertinoButton(
      child: new Text("Send"),
      onPressed: _isComposing
          ? () => _handleSubmitted(_textController.text)
          : null,
    )
        : new IconButton(
      icon: new Icon(Icons.send),
      onPressed: _isComposing
          ? () => _handleSubmitted(_textController.text)
          : null,
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Column(
            children: <Widget>[
              new Row(children: <Widget>[
                new Flexible(
                  child: new TextField(
                    controller: _textController,
                    onChanged: (String text) {
                      setState(() {
                        _isComposing = text.length > 0;
                      });
                    },
                    onSubmitted: _handleSubmitted,
                    decoration:
                    new InputDecoration.collapsed(hintText: "Send a message"),
                  ),
                ),
                new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildSendButton(),
                ),
              ]),
              new TabBar(
                tabs: MealDayType.values.map((m) => new Text(_toEmoji(m), style: new TextStyle(fontSize: 25.0))).toList(),
                controller: _tabMealController,
                indicator: new BoxDecoration(
                  border: new Border.all(color: Colors.indigo),
                  borderRadius: new BorderRadius.circular(30.0)

                ),
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
              border:
              new Border(top: new BorderSide(color: Colors.grey[200])))
              : null),
    );
  }

  Widget _cell(DayItem item) {
    return new Dismissible(key: new Key(item.date.toIso8601String()),
      onDismissed: (d) => _removeItem(item),
      background: _buildRemoveBackground(),
      child: new Column (
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              padding: new EdgeInsets.all(16.0),
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    child: new Text(_toEmoji(item.mealDayType), style: new TextStyle(fontSize: 25.0),),
                    padding: new EdgeInsets.only(right: 8.0),
                  ),
                  new Flexible (
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(item.text, style: new TextStyle(fontSize: 15.0)),
                            new Text(_toTime(item.date), style: new TextStyle(fontSize: 10.0)),
                          ],
                    )
                  ),
                ],
              ),
            ),
            new Divider(height: 1.0),
        ]
      ),
    );
  }

  Widget _buildRemoveBackground() {
    return new Container(
      padding: new EdgeInsets.all(16.0),
      alignment: Alignment.centerRight,
      color: Colors.red,
      child: new Text("Delete", style: new TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("Days"),
          elevation:
          Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0
      ),
      body: _buildBody()
    );
  }

  Widget _buildBody() {
    return _loadingInProgress ? _buildLoadingBody() : _buildItemListBody();
  }

  Widget _buildLoadingBody() {
    return new Center(
      child: new CircularProgressIndicator(),
    );
  }

  Widget _buildItemListBody() {
    return new Container(
        padding: new EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: new Column(
            children: <Widget>[
              new Flexible(
                  child: _buildList(),
              ),
              new Divider(height: 1.0),
              new Container(
                decoration: new BoxDecoration(
                    color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ]
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS ? new BoxDecoration(border: new Border(top: new BorderSide(color: Colors.grey[200]))) : null);
  }

  Widget _buildList() {
    return new ListView.builder (
      reverse: true,
      itemBuilder: (_, int index) => _cell(_items[index]),
      itemCount: _items.length,
      controller: _scrollController,
    );
  }

  String _toWeekDay(DateTime date) => new DateFormat('E').format(date);
  String _toTime(DateTime date) => new DateFormat('Hms').format(date);
  String _toEmoji(MealDayType mealDayType) {
    switch (mealDayType) {
      case MealDayType.breakfast:
        return '🍌';
      case MealDayType.lunch:
        return '🍲';
      case MealDayType.dinner:
        return '🥗';
      case MealDayType.snack:
        return '🌮';
      case MealDayType.candy:
        return '🍩';
    }
    return '';
  }
}

class DayItem {
  String text;
  DateTime date;
  MealDayType mealDayType;

  DayItem(this.text, this.mealDayType, [DateTime date]) {
    this.date = date ?? new DateTime.now();
  }

  DayItem.fromJson(Map<String, dynamic> json)
      : text = json['text'],
        mealDayType = MealDayType.values[json['mealDayTypeIndex'] ?? 0],
        date = DateTime.parse(json['date'],);

  Map<String, dynamic> toJson() =>
      {
        'text': text,
        'mealDayTypeIndex': mealDayType.index,
        'date': date.toIso8601String(),
      };
}
