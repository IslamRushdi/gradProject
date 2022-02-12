import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import'package:google_sign_in/google_sign_in.dart';
import 'package:webrtc_signaling_server/shared/components/constants.dart';

class GoogleSignInProvider extends ChangeNotifier{
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;



  Future googleLogin(bool isBlind) async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      _user = googleUser;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult =await FirebaseAuth.instance.signInWithCredential(credential);
      final User currentUser = authResult.user!;
      // check if user is new or exist.
      if (authResult.additionalUserInfo!.isNewUser) {
          CollectionReference users = FirebaseFirestore.instance.collection('Users');
          FirebaseAuth auth = FirebaseAuth.instance;
          String uid = auth.currentUser!.uid.toString();
          String displayName = auth.currentUser!.displayName.toString();
          String avatarURL = auth.currentUser!.photoURL.toString();
          String email = auth.currentUser!.email.toString();
          String? phoneNumber = auth.currentUser!.phoneNumber.toString();

          users.doc('$uid').set({
            'displayName': displayName,
            'avatarURL': avatarURL,
            'email':email,
            'phoneNumber': phoneNumber,
            'isBlind': isBlind,
          });
          // users.add(
          //     {
          //       'displayName': displayName,
          //       'uid': uid,
          //       'avatarURL': avatarURL,
          //       'email':email,
          //       'phoneNumber': phoneNumber,
          //       'isBlind': isBlind,
          //     });


        }

    } catch (e) {
      print(e.toString());
    }
    notifyListeners();
  }

  Future logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }

}