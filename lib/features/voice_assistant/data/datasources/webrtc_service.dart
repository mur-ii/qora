import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/entities/connection_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;

  ConnectionStateEntity _connectionState = ConnectionStateEntity.disconnected;

  // Callbacks
  Function(ConnectionStateEntity)? _onConnectionStateChange;
  Function(String)? _onTranscript;
  Function(FunctionCallEntity)? _onFunctionCall;
  Function(Map<String, dynamic>)? _onAgentEvent;

  ConnectionStateEntity get connectionState => _connectionState;

  /// Initialize WebRTC with Google STUN servers
  Future<void> initialize({
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    _onConnectionStateChange = onConnectionStateChange;
    _onTranscript = onTranscript;
    _onFunctionCall = onFunctionCall;
    _onAgentEvent = onAgentEvent;

    _updateConnectionState(ConnectionStateEntity.connecting);

    try {
      // Create peer connection with STUN servers
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      // Set up connection state listener
      _peerConnection!.onConnectionState = (state) {
        print('WebRTC Connection State: $state');
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _updateConnectionState(ConnectionStateEntity.connected);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _updateConnectionState(ConnectionStateEntity.failed);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _updateConnectionState(ConnectionStateEntity.disconnected);
            break;
          default:
            break;
        }
      };

      // Set up ICE candidate handler
      _peerConnection!.onIceCandidate = (candidate) {
        print('ICE Candidate: ${candidate.candidate}');
      };

      // Set up remote stream handler
      _peerConnection!.onTrack = (event) {
        print('Received remote track: ${event.track.kind}');
        if (event.track.kind == 'audio') {
          _playRemoteAudio(event.streams[0]);
        }
      };

      // Capture microphone audio
      await _captureAudio();

      // Create data channel for events
      await _createDataChannel();

      print('WebRTC initialized successfully');
    } catch (e) {
      print('Error initializing WebRTC: $e');
      _updateConnectionState(ConnectionStateEntity.failed);
      rethrow;
    }
  }

  /// Capture microphone audio with noise/echo suppression
  Future<void> _captureAudio() async {
    final constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      // Add audio tracks to peer connection
      _localStream!.getAudioTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
        print('Added audio track to peer connection');
      });
    } catch (e) {
      print('Error capturing audio: $e');
      rethrow;
    }
  }

  /// Create data channel for OpenAI events
  Future<void> _createDataChannel() async {
    final dataChannelInit = RTCDataChannelInit();
    dataChannelInit.ordered = true;

    _dataChannel = await _peerConnection!.createDataChannel(
      'oai-events',
      dataChannelInit,
    );

    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      _handleDataChannelMessage(message.text);
    };

    _dataChannel!.onDataChannelState = (state) {
      print('Data Channel State: $state');
    };

    print('Data channel created: oai-events');
  }

  /// Handle messages from data channel
  void _handleDataChannelMessage(String message) {
    try {
      if (message.isEmpty) return;

      final data = jsonDecode(message) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      if (eventType == null) {
        print('Warning: Received message without type field');
        return;
      }

      print('Received data channel event: $eventType');

      switch (eventType) {
        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _onTranscript?.call(transcript);
          }
          break;

        case 'response.function_call_arguments.done':
          final callId = data['call_id'] as String?;
          final name = data['name'] as String?;
          final argumentsStr = data['arguments'] as String?;

          if (callId != null && name != null && argumentsStr != null) {
            try {
              final arguments =
                  jsonDecode(argumentsStr) as Map<String, dynamic>;
              _onFunctionCall?.call(
                FunctionCallEntity(
                  callId: callId,
                  name: name,
                  arguments: arguments,
                ),
              );
            } catch (e) {
              print('Error parsing function arguments: $e');
            }
          }
          break;

        case 'response.audio_transcript.done':
          // AI's response transcript
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _onAgentEvent?.call(data);
          }
          break;

        case 'error':
          print('OpenAI Error: ${data['error']}');
          _onAgentEvent?.call(data);
          break;

        case 'session.updated':
        case 'conversation.item.created':
        case 'response.done':
        case 'response.created':
        case 'input_audio_buffer.speech_started':
        case 'input_audio_buffer.speech_stopped':
          _onAgentEvent?.call(data);
          break;

        default:
          // Log unknown events for debugging
          print('Unhandled event type: $eventType');
          _onAgentEvent?.call(data);
      }
    } catch (e) {
      print('Error handling data channel message: $e');
      print('Raw message: $message');
    }
  }

  /// Create SDP offer
  Future<String> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer.sdp!;
  }

  /// Set remote SDP answer
  Future<void> setRemoteAnswer(String sdpAnswer) async {
    final answer = RTCSessionDescription(sdpAnswer, 'answer');
    await _peerConnection!.setRemoteDescription(answer);
    print('Remote description set successfully');
  }

  /// Play remote audio stream with speakerphone enabled
  Future<void> _playRemoteAudio(MediaStream stream) async {
    try {
      // Enable speakerphone
      await Helper.setSpeakerphoneOn(true);
      print('Speakerphone enabled, playing remote audio');
    } catch (e) {
      print('Error playing remote audio: $e');
    }
  }

  /// Send function result via data channel
  Future<void> sendFunctionResult({
    required String callId,
    required dynamic result,
  }) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      print('Data channel not ready');
      return;
    }

    final assistantPrompt = result is Map<String, dynamic>
        ? result['assistant_prompt'] as String?
        : null;

    final message = jsonEncode({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': jsonEncode(result),
      },
    });

    _dataChannel!.send(RTCDataChannelMessage(message));
    print('Function result sent for call_id: $callId');

    final responseMessage = jsonEncode({
      'type': 'response.create',
      'response': {
        'modalities': ['text', 'audio'],
        if (assistantPrompt != null && assistantPrompt.isNotEmpty)
          'instructions': assistantPrompt
        else
          'instructions':
              'Berikan respons singkat dalam Bahasa Indonesia berdasarkan hasil fungsi.',
      },
    });

    _dataChannel!.send(RTCDataChannelMessage(responseMessage));
    print('Response requested after function output');
  }

  /// Send custom event via data channel
  Future<void> sendEvent(Map<String, dynamic> event) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      print('Data channel not ready');
      return;
    }

    final message = jsonEncode(event);
    _dataChannel!.send(RTCDataChannelMessage(message));
    print('Event sent: ${event['type']}');
  }

  /// Update connection state
  void _updateConnectionState(ConnectionStateEntity state) {
    _connectionState = state;
    _onConnectionStateChange?.call(state);
  }

  /// Mute/unmute microphone input
  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    if (_localStream == null) {
      print('Microphone stream not available');
      return;
    }

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !isMuted;
    }

    print(isMuted ? 'Microphone muted' : 'Microphone unmuted');
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      // Close data channel
      _dataChannel?.close();
      _dataChannel = null;

      // Stop local tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream?.dispose();
      _localStream = null;

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Disable speakerphone
      await Helper.setSpeakerphoneOn(false);

      _updateConnectionState(ConnectionStateEntity.disconnected);
      print('WebRTC disconnected and cleaned up');
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }
}
