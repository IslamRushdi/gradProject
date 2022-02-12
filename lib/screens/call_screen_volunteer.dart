import 'dart:convert';

import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:webrtc_signaling_server/shared/components/constants.dart';
import 'package:webrtc_signaling_server/utils/utils.dart';

class CallScreenVolunteer extends StatefulWidget {
  final bool isBlind;

  const CallScreenVolunteer({
    Key? key,
    required this.isBlind,
  }) : super(key: key);

  @override
  _CallScreenVolunteerState createState() => _CallScreenVolunteerState();
}

class _CallScreenVolunteerState extends State<CallScreenVolunteer> {
  String? _blindId;
  String? _volunteerId;
  bool isBusy = false;
  bool changer = false;
  String? _volunteerSdp;
  Map<String, dynamic>? _firstCandidate;

  bool _offer = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  late Socket socket;

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socket.disconnect();

    super.dispose();
  }

  @override
  void initState() {
    initRenderer();
    _initSocketConnection();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });

    // _getUserMedia();
    super.initState();
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initSocketConnection() {
    socket = io(
      'http://localhost:5000',
      // 'http://3264-41-233-95-226.ngrok.io ',
      OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
          .build(),
    ).open();
    socket.onConnect((_) {
      print("connected");
      _volunteerId = socket.id;
      print("connected to room with id:$_volunteerId");

      print("isBlind: ${widget.isBlind}");
      socket.emit("volunteer: connect to room");
      socket
          .on("server: send blind connection to all volunteers to create offer",
              (blindData) {
        blindData = blindData as Map<String, dynamic>;
        final String blindSdp = blindData['sdp']! as String;
        _blindId = blindData['id']! as String;

        // print("blindSdp: $blindSdp");
        //print("id: $_blindId");
        print('recieving sdp');
        if (!isBusy) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.black,
              content: Text(
                'Blind User is Calling ...',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    isBusy = true;
                    _setRemoteDescription(blindSdp);
                    _createAnswer();
                    changer = true;
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.call,
                      color: Colors.white,
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    changer = false;
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            barrierDismissible: false,
          );
        }
      });
    });
  }

  _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream!);

    pc.onIceCandidate = (RTCIceCandidate e) {
      if (e.candidate != null && _firstCandidate == null) {
        Map<String, dynamic> candidateConstraints = {
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        };

        _firstCandidate = candidateConstraints;

        print(candidateConstraints);
        print("_blindId= $_blindId");

        if (_blindId != null) {
          Map<String, dynamic> candidateInvitation = {
            "candidate": candidateConstraints,
            "sdp": _volunteerSdp,
            "blindId": _blindId!,
          };

          socket.emit(
            'volunteer: send sdp, candidate and blind id',
            candidateInvitation,
          );
          print('sending sdp...');
          // socket.disconnect();
        }
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

    _localRenderer.srcObject = stream;
    // _localRenderer.mirror = true;

    return stream;
  }

  void _createAnswer() async {
    //_handleReceivingBlindCandidate();

    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
    if (description.sdp != null) _volunteerSdp = description.sdp;

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription(String sdp) async {
    // RTCSessionDescription description =
    //     new RTCSessionDescription(session['sdp'], session['type']);
    RTCSessionDescription description =
        new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');

    await _peerConnection!.setRemoteDescription(description);
    print('remote description is set');
  }

  void _handleReceivingBlindCandidate() {
    socket.on('server: send blind candidate', (blindCandidate) async {
      blindCandidate = blindCandidate as Map<String, dynamic>;

      print(blindCandidate['candidate']);
      RTCIceCandidate candidate = new RTCIceCandidate(
        blindCandidate['candidate'],
        blindCandidate['sdpMid'],
        blindCandidate['sdpMlineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    });
  }

  bool isMuted = false;
  bool isDeafened = false;
  bool switchCamera = false;
  bool isVideoOff = false;

  IconData muted = Icons.mic;
  IconData deafened = Icons.headset;
  IconData whichCamera = Icons.flip_camera_ios;
  IconData videoOff = Icons.videocam;

  void _mute() {
    if (!isDeafened) {
      isMuted = !isMuted;
      _localStream!.getAudioTracks()[0].enabled =
          !_localStream!.getAudioTracks()[0].enabled;
    }
    muted = isMuted ? Icons.mic_off : Icons.mic;
    setState(() {
      print("Toggle Mute");
    });
  }

  void _deafen() {
    if ((_localStream!.getAudioTracks()[0].enabled &&
            _peerConnection!
                .getRemoteStreams()[0]!
                .getAudioTracks()[0]
                .enabled) ||
        (!_localStream!.getAudioTracks()[0].enabled &&
            !_peerConnection!
                .getRemoteStreams()[0]!
                .getAudioTracks()[0]
                .enabled)) {
      _localStream!.getAudioTracks()[0].enabled =
          !_localStream!.getAudioTracks()[0].enabled;

      _peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled =
          !_peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled;

      if (_localStream!.getAudioTracks()[0].enabled) {
        isMuted = false;
      } else if (!_localStream!.getAudioTracks()[0].enabled) {
        isMuted = true;
      }
      if (_peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled) {
        isDeafened = false;
      } else if (!_peerConnection!
          .getRemoteStreams()[0]!
          .getAudioTracks()[0]
          .enabled) {
        isDeafened = true;
      }
    } else if (!_localStream!.getAudioTracks()[0].enabled &&
        _peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled) {
      _peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled =
          !_peerConnection!.getRemoteStreams()[0]!.getAudioTracks()[0].enabled;

      isDeafened = true;
    }
    deafened = isDeafened ? Icons.headset_off : Icons.headset;
    muted = isMuted ? Icons.mic_off : Icons.mic;
    setState(() {});
  }

  void _switchCamera() async {
    whichCamera = Icons.flip_camera_ios;

    if (switchCamera) {
      await _localStream!.getVideoTracks()[0].switchCamera();
    }
    setState(() {});
  }

  void _videoOff() {
    videoOff = isVideoOff ? Icons.videocam_off : Icons.videocam;
    if (isVideoOff) {
      _localStream!.getVideoTracks()[0].enabled =
          !_localStream!.getVideoTracks()[0].enabled;
    }
    setState(() {});
  }

  void _smallDispose() {
    setState(() {
      isBusy = false;
      changer = false;
      _remoteRenderer.srcObject = null;
    });
  }

  SizedBox videoRenderers() => SizedBox(
      height: 500,
      child: Row(children: [
        Flexible(
          child: new Container(
              key: new Key("local"),
              margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: new BoxDecoration(color: Colors.black),
              child: new RTCVideoView(
                _localRenderer,
                mirror: true,
              )),
        ),
        Flexible(
          child: new Container(
              key: new Key("remote"),
              margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: new BoxDecoration(color: Colors.black),
              child: new RTCVideoView(_remoteRenderer)),
        )
      ]));

  Row volunteerWaitingState() =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text(
          'Waiting for blind user to call ',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        CircularProgressIndicator(
          color: Colors.grey,
        ),
      ]);

  Row volunteerCallState() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              onPressed: () {
                _mute();
              },
              icon: Icon(
                muted,
                color: isMuted ? Colors.red : Colors.white,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              color: Colors.black,
              onPressed: () {
                _deafen();
              },
              icon: Icon(
                deafened,
                color: isDeafened ? Colors.red : Colors.white,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              color: Colors.black,
              onPressed: () {
                switchCamera = !switchCamera;
                _switchCamera();
              },
              icon: Icon(
                whichCamera,
                color: Colors.white,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              color: Colors.black,
              onPressed: () {
                isVideoOff = !isVideoOff;
                _videoOff();
              },
              icon: Icon(
                videoOff,
                color: isVideoOff ? Colors.red : Colors.white,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              icon: Icon(
                Icons.call_end,
                color: Colors.red,
              ),
            ),
          ),
        ],
      );

  Row volunteerProperties() {
    if (changer)
      return volunteerCallState();
    else
      return volunteerWaitingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Video Conference'),
        ),
        body: Container(
            child: Container(
                child: Column(
          children: [
            videoRenderers(),
            SizedBox(
              height: 20.0,
            ),
            volunteerProperties(),
          ],
        ))));
  }
}
