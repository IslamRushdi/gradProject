// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:webrtc_signaling_server/shared/components/constants.dart';

// class IncomingCallScreen extends StatefulWidget {
//   const IncomingCallScreen({Key? key}) : super(key: key);

//   @override
//   _IncomingCallScreenState createState() => _IncomingCallScreenState();
// }

// class _IncomingCallScreenState extends State<IncomingCallScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: AlertDialog(
//         shape: CircleBorder(),
//         backgroundColor: Colors.black,
//         content: Text('Blind User is Calling You',
//         style: TextStyle(
//         fontSize: 20.0,
//         fontWeight: FontWeight.bold,
//         color: Colors.white,
//         ),
//         ),
//         actions: [
//           CircleAvatar(
//               backgroundColor: Colors.green,
//               child: IconButton(
//                 onPressed: () {
//                   blindCallingRequest = true;
//                 },
//                 icon: Icon(
//                   Icons.call,
//                   color: Colors.white,
//                 ),
//               ),
//           ),
            
//             CircleAvatar(
//               backgroundColor: Colors.red,
//               child: IconButton(
//                 onPressed: () {
//                   blindCallingRequest = false;
//                 },
//                 icon: Icon(
//                   Icons.call_end,
//                   color: Colors.white,
//                 ),
//               ),
//         ],
//         ), 
//         /* Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             CircleAvatar(
//               backgroundColor: Colors.green,
//               child: IconButton(
//                 onPressed: () {
//                   blindCallingRequest = true;
//                   AlertDialog.
//                 },
//                 icon: Icon(
//                   Icons.call,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             CircleAvatar(
//               backgroundColor: Colors.red,
//               child: IconButton(
//                 onPressed: () {
//                   blindCallingRequest = false;
//                 },
//                 icon: Icon(
//                   Icons.call_end,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),*/
//       ),
//     );
//   }
// }
