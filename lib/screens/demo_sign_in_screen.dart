import 'package:flutter/material.dart';
import 'package:webrtc_signaling_server/screens/blind_vs_volunteer_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DemoSignInScreen extends StatefulWidget {
  const DemoSignInScreen({Key? key}) : super(key: key);

  @override
  _DemoSignInScreenState createState() => _DemoSignInScreenState();
}

class _DemoSignInScreenState extends State<DemoSignInScreen> {

  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  @override
  Widget build(BuildContext context) {
    GoogleSignInAccount? user = _googleSignIn.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: Text(' See For Me ',
        style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.bold,
        ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Text('Google Sign In (Signed '+(user == null ? 'out':'in')+')'),
          ElevatedButton(onPressed: user != null ? null : () async{
              await _googleSignIn.signIn();
              setState(() {

              });
              },
                  child: Text("Sign In",),
              ),
          ElevatedButton(onPressed:user == null ? null: () async{
            await _googleSignIn.signOut();
            setState(() {

            });
          },
                  child: Text("Sign Out",),
              ),
          // ElevatedButton(onPressed: (){
          //         Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //         builder: (context) => BlindVSVolunteerScreen(),
          //       ),);
          //     },
          //         child: Text("Please Enter",),
          //     ),


            ],
          ),


    );
  }
}
