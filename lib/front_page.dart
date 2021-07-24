import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_gradient_app_bar/new_gradient_app_bar.dart';
import 'map_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:telephony/telephony.dart';

class FrontPage extends StatefulWidget {
  final String user, pass;
  const FrontPage({Key? key, required this.user, required this.pass}) : super(key: key);

  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {

  List incidentList = [];
  int a = 1;

  RefreshController _refreshController = RefreshController(initialRefresh: false);
  final Telephony telephony = Telephony.instance;
  final _formkey = GlobalKey<FormState>();



  void _onRefresh() async{
    await Future.delayed(Duration(milliseconds: 1000));
    Navigator.push(context, MaterialPageRoute(builder: (context)=>FrontPage(
      user: widget.user,
      pass: widget.pass,
    )));
    _refreshController.refreshCompleted();
  }

  // void _onLoading() async{
  //   await Future.delayed(Duration(milliseconds: 1000));
  //
  //   if(mounted){
  //     setState(() {
  //
  //     });
  //   }
  // }

  Future getInfoList() async{
    var url = Uri.parse("http://192.168.43.225:8080/ambulance/infoList.php");

    var response = await http.get(url);
    setState(() {
      incidentList = json.decode(response.body);
    });
    return incidentList;
  }

  // _sendSMS(index) async {
  //   int _sms = 0;
  //   while (_sms < int.parse(_valueSms.text)) {
  //     telephony.sendSms(to: incidentList[index]['first_name'], message: _msgController.text);
  //     _sms ++;
  //   }
  // }

  Future _updateStatus(index) async{
    // print(index);
    // print('milky');
    var url = Uri.parse("http://192.168.43.225:8080/ambulance/updateStatus.php");

    var response = await http.post(url, body: {
      "id": index,
      "user":widget.user
    });
    var data = json.decode(response.body);
    if(data == "success"){
      Fluttertoast.showToast(
          msg: "Successfully updated!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Colors.green,
          fontSize:25
      );
    }else{
      Fluttertoast.showToast(
          msg: "Error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize:25
      );
    }
    // int _sms = 0;
    // while (_sms < int.parse(_valueSms.text)) {
      telephony.sendSms(to: incidentList[index]['first_name'], message: 'Ambulance is on its way');
    _getSMS(index);
  }

  _getSMS(index) async {
    List<SmsMessage> _messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(incidentList[index]['first_name'])
    );
    print("milky");
    print(_messages);
    // _sms ++;
  }

  Future<void> _showMyDialog(index) async{
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context){
          return AlertDialog(
            title: const Text('Emergency'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(incidentList[index]['first_name']+' '
                      ''+incidentList[index]['last_name']+' is having '+
                      incidentList[index]['incident_name'])
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text('Accept'),
                  onPressed: (){
                    Fluttertoast.showToast(
                        msg: "Accepted!!",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.white,
                        textColor: Colors.green,
                        fontSize:25
                    );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MapPage(
                                incidentLatitude: double.parse(incidentList[index]['latitude']),
                                incidentLongitude: double.parse(incidentList[index]['longitude']))
                        )
                    );
                    _updateStatus(incidentList[index]['id']);
                    // _sendSMS(index);
                    // Navigator.of(context).pop();
                  },
              )
            ],
          );
        }
    );
  }
  @override
  void initState() {
    getInfoList();
  }
  final topAppBar = AppBar(
    automaticallyImplyLeading: false,
    elevation: 0.1,
    backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
    title: Text('Incident Information',
      style: TextStyle(color: Colors.white),),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.list),
        onPressed: () {},
      )
    ],

  );
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
      appBar: topAppBar,
      // AppBar(
        // toolbarHeight: 70,
        // title: Text('Emergency Incident Information',),
        // flexibleSpace: ClipRRect(
        //   // borderRadius: BorderRadius.only(bottomRight: Radius.circular(50), bottomLeft: Radius.circular(50)),
        //   child: Container(
        //     color: Colors.blueAccent,
        //     // decoration: BoxDecoration(
        //     //   image: DecorationImage(
        //     //     image: AssetImage('assets/emer.jpg'),
        //     //     fit: BoxFit.fill,
        //     //       colorFilter: ColorFilter.mode(Colors.red.withOpacity(0), BlendMode.darken)
        //     //
        //     //   )
        //     // ),
        //   ),
        // ),
      // ),
      body: SmartRefresher(
        enablePullUp: true,
        enablePullDown: true,
        header: WaterDropHeader(),
        controller: _refreshController,
        onRefresh: _onRefresh,
        // onLoading: _onLoading,
        child: ListView.builder(
            itemCount: incidentList.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (context, index){
              return Card(
                elevation: 8.0,
                margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Container(
                    decoration: BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      // tileColor: Color.fromRGBO(58, 66, 86, 1.0),
                      onTap: (){
                        _showMyDialog(index);
                      },
                      leading: Container(
                        padding: EdgeInsets.only(right: 12.0),
                        decoration: new BoxDecoration(
                            border: new Border(
                                right: new BorderSide(width: 1.0, color: Colors.white24)
                            )
                        ),
                        child: Icon(Icons.person,color: Colors.white,),
                      ),
                      title: Text(incidentList[index]['first_name']+' '+incidentList[index]['last_name'],
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold),),
                      subtitle: Text(incidentList[index]['incident_name'],
                        style: TextStyle(color: Colors.white),),
                      trailing: RaisedButton(onPressed: (){
                        Fluttertoast.showToast(
                            msg: "Accepted!!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: Colors.green,
                            fontSize:25
                        );
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MapPage(
                                    incidentLatitude: double.parse(incidentList[index]['latitude']),
                                    incidentLongitude: double.parse(incidentList[index]['longitude']))
                            )
                        );
                        // Navigator.of(context).pop();
                        _updateStatus(incidentList[index]['id']);
                      },
                        color: Colors.green,
                        child: Icon(Icons.visibility_outlined,
                          color: Colors.white,
                          size: 30.0,),),
                    )
                ),
              );
            }
        ),
      )
    );
  }
}
