import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:webrtc_signaling_server/utils/utils.dart';

class CallScreenBlind extends StatefulWidget {
  final bool isBlind;

  const CallScreenBlind({
    Key? key,
    required this.isBlind,
  }) : super(key: key);

  @override
  _CallScreenBlindState createState() => _CallScreenBlindState();
}

class _CallScreenBlindState extends State<CallScreenBlind> {
  String? blindId;
  String? roomId;
  String? VolunteerID;

  bool _offer = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  late Socket socket;
  bool timeout = true;
  FlutterTts flutterTts = FlutterTts();

  AudioPlayer audioPlayer = AudioPlayer();
  PlayerState playerState = PlayerState.PAUSED;
  AudioCache? audioCache;
  String path = 'app_running.mp3';

  playMusic() async {
    await audioCache?.loop(path);
  }

  pauseMusic() async {
    await audioPlayer.pause();
  }

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socket.disconnect();
    audioPlayer.release();
    audioPlayer.dispose();
    audioCache?.clearAll();
    super.dispose();
  }

  @override
  void initState() {
    initRenderer();
    _initSocketConnection();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });
    initTts();
    audioCache = AudioCache(fixedPlayer: audioPlayer);
    audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      setState(() {
        playerState = s;
      });
    });
    super.initState();
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  initTts() async {
    await flutterTts.setLanguage("en-us");
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.4);
  }

  void _initSocketConnection() {
    //ws://ad30-41-234-2-218.ngrok.io/
    socket = io(
      'http://localhost:5000',
      //'http://3264-41-233-95-226.ngrok.io /',
      OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
          .build(),
    ).open();
    socket.onConnect((_) {
      print("connected");
      blindId = socket.id;
      print("connected to server with id:$blindId");

      print("isBlind: ${widget.isBlind}");

      socket.on('server: Call ended', (_) {
        print("volunteer closed");
        Navigator.pop(context);
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

    return stream;
  }

  void _createOffer() async {
    _handleReceivingNoVolunteerFound();

    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    String blindSdp = description.sdp!;
    socket.emit("blind: send sdp", blindSdp);
    print("sending sdp...");
    _offer = true;
    _peerConnection!.setLocalDescription(description);
    _handleReceivingVolunteerCandidate();
    playMusic();
    timeout = false;
    showDialog(
        context: context,
        builder: (context) {
          Future.delayed(Duration(seconds: 20), () {
            pauseMusic();
            timeout = true;
            Navigator.pop(context);
          });
          return AlertDialog(
            title: Text(
              'waiting for Volunteer to answer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue,
          );
        });
  }

  void _handleReceivingNoVolunteerFound() {
    socket.on("server: no volunteer found", (_) {
      showSnackBar(context, "No volunteer found");
    });
    changer = false;
    setState(() {});
  }

  void _handleReceivingVolunteerCandidate() {
    socket.on('server: send volunteer candidate and sdp',
        (volunteerInformation) async {
      Map<String, dynamic> volunteerCandidate =
          volunteerInformation['candidate'] as Map<String, dynamic>;

      String volunteerSdp = volunteerInformation['sdp'] as String;
      VolunteerID = volunteerInformation['id'];

      RTCIceCandidate candidate = new RTCIceCandidate(
        volunteerCandidate['candidate'],
        volunteerCandidate['sdpMid'],
        volunteerCandidate['sdpMlineIndex'],
      );
      print('recieving sdp...');
      await _setRemoteDescription(volunteerSdp);
      print('Remote sdp is set');
      await _peerConnection!.addCandidate(candidate);
      print('candidate is set');
      if (!timeout) {
        Navigator.pop(context);
        pauseMusic();
      }
    });
  }

  Future<void> _setRemoteDescription(String sdp) async {
    RTCSessionDescription description =
        new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print('Remote Description is set');

    await _peerConnection!.setRemoteDescription(description);
    changer = true;
    setState(() {});
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
        ),
      ]));

  bool isMuted = false;
  bool isDeafened = false;
  bool switchCamera = false;
  bool isVideoOff = false;

  IconData muted = Icons.mic;
  IconData deafened = Icons.headset;
  IconData whichCamera = Icons.flip_camera_ios;
  IconData videoOff = Icons.videocam;

  Color colorMuted = Colors.white;
  Color colorDeafen = Colors.white;
  Color colorVideoOff = Colors.white;

  void _mute() {
    if (!isDeafened) {
      isMuted = !isMuted;
      _localStream!.getAudioTracks()[0].enabled =
          !_localStream!.getAudioTracks()[0].enabled;
    }
    muted = isMuted ? Icons.mic_off : Icons.mic;
    colorMuted = isMuted ? Colors.red : Colors.white;
    setState(() {
      print('Toggle mute');
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
    colorDeafen = isDeafened ? Colors.red : Colors.white;
    setState(() {
      print('Toggle Deafen');
    });
  }

  void _switchCamera() async {
    whichCamera = Icons.flip_camera_ios;

    if (switchCamera) {
      await _localStream!.getVideoTracks()[0].switchCamera();
    }
    switchCamera = !switchCamera;
    setState(() {
      print('Toggle Camera');
      switchCamera = !switchCamera;
    });
  }

  void _videoOff() {
    videoOff = isVideoOff ? Icons.videocam_off : Icons.videocam;
    colorVideoOff = isVideoOff ? Colors.red : Colors.white;
    if (isVideoOff) {
      _localStream!.getVideoTracks()[0].enabled =
          !_localStream!.getVideoTracks()[0].enabled;
    }
    setState(() {
      print('Toggle Video Availability');
      isVideoOff = !isVideoOff;
    });
  }

  void _smallDispose() {
    socket.emit("blind: Call ended", VolunteerID);
    Navigator.pop(context);
  }

  bool changer = false;

  Column blindProperties() {
    if (changer)
      return blindCallState();
    else
      return offerState();
  }

  Column blindCallState() => Column(
        children: [
          GestureDetector(
            onTap: () {
              _mute();
              print('Mute is Pressed');
              if (isMuted)
                _speak('Mic off');
              else
                _speak('Mic on');
            },
            onDoubleTap: () {
              _deafen();
              print('Deafen is pressed');
              if (isDeafened)
                _speak('Speakers off');
              else
                _speak('Speakers on');
            },
            onLongPress: () {
              print('Close Call');
              _speak('Closing  call');
              _smallDispose();
              setState(() {});
            },
            // onVerticalDragEnd: (Details){
            //   print('Switch Camera');
            //   _speak('Switching camera');
            //   _switchCamera();
            // },
            onHorizontalDragEnd: (Details) {
              print('Video Off');
              _videoOff();
              if (isVideoOff)
                _speak('Video off');
              else
                _speak('Video on');
            },

            child: videoRenderers(),
          ),
          SizedBox(
            height: 30.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(
                key: Key('Mute Operator'),
                backgroundColor: Colors.black,
                child: Icon(
                  muted,
                  color: colorMuted,
                ),
              ),
              CircleAvatar(
                key: Key('Deafen Operator'),
                backgroundColor: Colors.black,
                child: Icon(
                  deafened,
                  color: colorDeafen,
                ),
              ),
              CircleAvatar(
                key: Key('Camera Operator'),
                backgroundColor: Colors.black,
                child: Icon(
                  whichCamera,
                  color: Colors.white,
                ),
              ),
              CircleAvatar(
                key: Key('VideoOff Operator'),
                backgroundColor: Colors.black,
                child: Icon(
                  videoOff,
                  color: colorVideoOff,
                ),
              ),
              CircleAvatar(
                key: Key('Close Call Operator'),
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      );
  Column offerState() => Column(
        children: [
          GestureDetector(
            onLongPress: () {
              print('Blind Calling Other Volunteers');
              _speak('Starting Call');
              _createOffer();
              setState(() {});
            },
            child: videoRenderers(),
          ),
          SizedBox(
            height: 30.0,
          ),
        ],
      );

  Future _speak(String wordsToSay) async {
    await flutterTts.speak(wordsToSay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Conference'),
      ),
      body: blindProperties(),
    );
  }
}
