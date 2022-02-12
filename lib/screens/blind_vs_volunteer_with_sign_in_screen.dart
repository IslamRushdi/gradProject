
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:webrtc_signaling_server/shared/logged_in_widget.dart';
import 'package:webrtc_signaling_server/shared/sign_up_widget.dart';

class BlindVSVolunteerNewScreen extends StatefulWidget {
  const BlindVSVolunteerNewScreen({Key? key}) : super(key: key);

  @override
  _BlindVSVolunteerNewScreenState createState() => _BlindVSVolunteerNewScreenState();
}

class _BlindVSVolunteerNewScreenState extends State<BlindVSVolunteerNewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
              return Center (child: CircularProgressIndicator());
            }
          else if (snapshot.hasError) {
            return Center(child: Text('Something Went Wrong!',),);
          }
          else if (snapshot.hasData) {
            return LoggedInWidget();
          }
          else {
            return SignUpWidget();
          }
        },
      ),

    );
  }
}





