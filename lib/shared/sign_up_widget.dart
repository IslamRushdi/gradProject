
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'google_sign_in_provider.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({Key? key}) : super(key: key);

  @override
  _SignUpWidgetState createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  late bool isBlind;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade700,
      body: Container(
        padding: EdgeInsets.all(16.0,),
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text('See For Me',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.0,),
              Text('Welcome Back :)',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40.0,),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueGrey.shade600,
                  onPrimary: Colors.black,
                  minimumSize: Size(
                    double.infinity,
                    50,
                  ),
                ),
                onPressed: (){
                  final provider = Provider.of<GoogleSignInProvider>(context,listen:false);
                  provider.googleLogin(isBlind);
                },
                icon: Icon(
                  FontAwesomeIcons.google,
                  color: Colors.red,
                ),
                label: Text(
                  'Sign Up with Google',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height:16.0,),
              ElevatedButton(onPressed: (){isBlind=true;}, child: Text('Blind')),
              ElevatedButton(onPressed: (){isBlind=false;}, child: Text('Volunteer')),
            ],
          ),
        ),
    );
  }
}
