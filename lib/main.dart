import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:webrtc_signaling_server/screens/blind_vs_volunteer_with_sign_in_screen.dart';

import 'package:webrtc_signaling_server/shared/google_sign_in_provider.dart';

import 'screens/blind_vs_volunteer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
//  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //return ChangeNotifierProvider(
    //  create: (context)=> GoogleSignInProvider(),
    //  child:
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlindVSVolunteerScreen(),
      //   ),
    );
  }
}
