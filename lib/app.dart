import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:atsign_atmosphere_app/services/navigation_service.dart';
import 'package:atsign_atmosphere_app/view_models/add_contact_provider.dart';
import 'package:atsign_atmosphere_app/view_models/blocked_contact_provider.dart';
import 'package:atsign_atmosphere_app/view_models/contact_provider.dart';
import 'package:atsign_atmosphere_app/view_models/file_picker_provider.dart';
import 'package:atsign_atmosphere_app/view_models/history_provider.dart';
import 'package:atsign_atmosphere_app/view_models/test_model.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'routes/routes.dart';

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        print("Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        print("Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TestModel>(
          create: (context) => TestModel(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
            create: (context) => HistoryProvider()),
        ChangeNotifierProvider<AddContactProvider>(
            create: (context) => AddContactProvider()),
        ChangeNotifierProvider<FilePickerProvider>(
            create: (context) => FilePickerProvider()),
        ChangeNotifierProvider<ContactProvider>(
            create: (context) => ContactProvider()),
        ChangeNotifierProvider<BlockedContactProvider>(
            create: (context) => BlockedContactProvider())
      ],
      child: MaterialApp(
        title: 'AtSign Atmosphere App',
        debugShowCheckedModeBanner: false,
        initialRoute: SetupRoutes.initialRoute,
        navigatorKey: NavService.navKey,
        theme: ThemeData(
          fontFamily: 'HelveticaNeu',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            color: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        routes: SetupRoutes.routes,
      ),
    );
  }
}
