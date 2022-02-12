import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webrtc_signaling_server/models/user_data.dart';
// import 'package:webrtc_signaling_server/screens/blind_vs_volunteer_screen.dart';
import 'package:webrtc_signaling_server/screens/call_screen_blind.dart';
import 'package:webrtc_signaling_server/screens/call_screen_volunteer.dart';
import 'package:webrtc_signaling_server/shared/google_sign_in_provider.dart';

class LoggedInWidget extends StatefulWidget {
  const LoggedInWidget({Key? key}) : super(key: key);

  @override
  _LoggedInWidgetState createState() => _LoggedInWidgetState();
}

class _LoggedInWidgetState extends State<LoggedInWidget> {
    final User user = FirebaseAuth.instance.currentUser!;
     UserData? userData;

   // late DocumentSnapshot<Map<String,dynamic>> snap;
   // 1 'displayName': displayName, Done
   // 2 'uid': uid, Done
   // 3 'avatarURL': avatarURL, Done
   // 4 'email':email, Done
   // 5 'phoneNumber': phoneNumber, Done
   // 6 'isBlind': isBlind, Done

    @override
  void initState()  {
    super.initState();
    _getSnap();

  }
 void _getSnap  ()async{
   Stream<DocumentSnapshot<Map<String, dynamic>>>  snap =
       await FirebaseFirestore.instance
       .collection('Users')
       .doc(user.uid)
       .snapshots() ;
       snap.forEach((element) {
         setState(() {
           userData = UserData.fromMap(element.data()!);

         });
         print(userData);
       });

    }

  @override
  Widget build(BuildContext context) {
    //FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
    //FirebaseFirestore.instance
    //             .collection('Users')
    //             .where('uid',isEqualTo: user.uid)
    //              .snapshots(),
    // if (snap.hasError)
    // {
    //   return Text('error:${snap.error}');
    // }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text('Logged In',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
            onPressed: (){
              final provider = Provider.of<GoogleSignInProvider>(context, listen:false);
              provider.logout();
            },
          ),
        ],

      ),
      body: Container(
        alignment: Alignment.center,
        color: Colors.blueGrey.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30.0,
              backgroundColor:
                  userData!.isBlind!? Colors.blue : Colors.purple,
              child: Text(
                userData!.isBlind!? 'Blind':'volunteer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: Colors.white,
                ),

              ),

            ),
            SizedBox(height: 32.0,),
            Text(
              userData!.displayName !=null ?
              'Welcome '+userData!.displayName!:
              'Name is not contained',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32.0,),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                  userData!.avatarURL !=null ?
                  userData!.avatarURL!:
                  'https://www.elbalad.news/UploadCache/libfiles/904/7/600x338o/303.jpg'
                      
              ),
            ),
            SizedBox(height: 8,),
            Text(
              userData!.phoneNumber !=null ?
              'phoneNumber: '+userData!.phoneNumber!:
              'phone number is not contained',
              style: TextStyle(color: Colors.white,fontSize: 16),
            ),
            SizedBox(height: 8,),
            Text(
              'Email: '+userData!.email!,
              style: TextStyle(color: Colors.white,fontSize: 16),
            ),
            SizedBox(height: 32.0,),
            ElevatedButton.icon(
              icon: Icon(
                FontAwesomeIcons.video,
                color: Colors.red,
              ),
              label: Text(
                'Start VideoCall',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.blueGrey.shade700,
                onPrimary: Colors.black,
                minimumSize: Size(
                  double.infinity,
                  50,
                ),),
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => userData!.isBlind!?
                    CallScreenBlind(isBlind: userData!.isBlind!)
                        : CallScreenVolunteer(isBlind: userData!.isBlind!),
                  ),
                );
              },

            ),

          ],

        ),
       ),
    );

  }


}
