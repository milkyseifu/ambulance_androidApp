import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class SmsMessage extends StatefulWidget {
  const SmsMessage({Key? key}) : super(key: key);

  @override
  _SmsMessageState createState() => _SmsMessageState();
}

class _SmsMessageState extends State<SmsMessage> {
  final Telephony telephony = Telephony.instance;
  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
