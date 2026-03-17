import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/services/performance_runtime_metrics_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/connection_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../domain/usecases/voice_conversation_logger.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;

  final VoiceConversationLogger? _conversationLogger;
  final PerformanceRuntimeMetricsService _runtimeMetrics =
      PerformanceRuntimeMetricsService.instance;

  Timer? _statsPollingTimer;
  int _lastWebRtcBytesSent = 0;
  int _lastWebRtcBytesReceived = 0;

  ConnectionStateEntity _connectionState = ConnectionStateEntity.disconnected;

  // Callbacks
  Function(ConnectionStateEntity)? _onConnectionStateChange;
  Function(String)? _onTranscript;
  Function(FunctionCallEntity)? _onFunctionCall;
  Function(Map<String, dynamic>)? _onAgentEvent;

  ConnectionStateEntity get connectionState => _connectionState;

  WebRTCService({VoiceConversationLogger? conversationLogger})
    : _conversationLogger = conversationLogger;

  /// Initialize WebRTC with Google STUN servers
  Future<void> initialize({
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
    String? modelName,
  }) async {
    if (_peerConnection != null || _dataChannel != null) {
      await disconnect();
    }

    _onConnectionStateChange = onConnectionStateChange;
    _onTranscript = onTranscript;
    _onFunctionCall = onFunctionCall;
    _onAgentEvent = onAgentEvent;

    _conversationLogger?.setModelName(modelName);

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
      _conversationLogger?.logLifecycle('WebRTC peer connection created');

      // Set up connection state listener
      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          AppLogger.info('WebRTC', 'Connection state: connected');
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          AppLogger.warn('WebRTC', 'Connection state: failed');
          _conversationLogger?.logError('WebRTC connection failed');
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          AppLogger.warn('WebRTC', 'Connection state: disconnected');
        }
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _startStatsPolling();
            _updateConnectionState(ConnectionStateEntity.connected);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _stopStatsPolling();
            _updateConnectionState(ConnectionStateEntity.failed);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _stopStatsPolling();
            _updateConnectionState(ConnectionStateEntity.disconnected);
            break;
          default:
            break;
        }
      };

      // Set up ICE candidate handler
      _peerConnection!.onIceCandidate = (candidate) {
        // Intentionally quiet: ICE candidates are noisy in logs.
      };

      // Set up remote stream handler
      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'audio') {
          _playRemoteAudio(event.streams[0]);
        }
      };

      // Capture microphone audio
      await _captureAudio();
      _conversationLogger?.logLifecycle('Microphone stream started');

      // Create data channel for events
      await _createDataChannel();
    } catch (e, stackTrace) {
      AppLogger.error(
        'WebRTC',
        'Error initializing WebRTC',
        error: e,
        stackTrace: stackTrace,
      );
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
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'WebRTC',
        'Error capturing audio',
        error: e,
        stackTrace: stackTrace,
      );
      final message = e.toString().toLowerCase();
      if (message.contains('permission') || message.contains('notallowed')) {
        throw Exception('Microphone permission denied');
      }
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
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        AppLogger.info('WebRTC', 'Data channel: open');
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        AppLogger.warn('WebRTC', 'Data channel: closed');
      }
    };
  }

  /// Handle messages from data channel
  void _handleDataChannelMessage(String message) {
    try {
      if (message.isEmpty) return;

      final data = jsonDecode(message) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      _conversationLogger?.logRealtimeEvent(data);

      if (eventType == null) {
        AppLogger.warn('WebRTC', 'Received message without type field');
        return;
      }

      switch (eventType) {
        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _onTranscript?.call(transcript);
          }
          break;

        case 'input_audio_buffer.speech_started':
          _onAgentEvent?.call(data);
          break;

        case 'input_audio_buffer.speech_stopped':
          _onAgentEvent?.call(data);
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
            } catch (e, stackTrace) {
              AppLogger.error(
                'WebRTC',
                'Error parsing function arguments',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
          break;

        case 'response.function_call_arguments.delta':
          _onAgentEvent?.call(data);
          break;

        case 'response.audio_transcript.done':
          // AI's response transcript
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _onAgentEvent?.call(data);
          }
          break;

        case 'error':
          AppLogger.error('WebRTC', 'OpenAI error: ${data['error']}');
          _onAgentEvent?.call(data);
          break;

        case 'session.updated':
        case 'conversation.item.created':
        case 'response.done':
        case 'response.created':
          _onAgentEvent?.call(data);
          break;

        default:
          _onAgentEvent?.call(data);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'WebRTC',
        'Error handling data channel message',
        error: e,
        stackTrace: stackTrace,
      );
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
  }

  /// Play remote audio stream with speakerphone enabled
  Future<void> _playRemoteAudio(MediaStream stream) async {
    try {
      // Enable speakerphone
      await Helper.setSpeakerphoneOn(true);
    } catch (e, stackTrace) {
      AppLogger.error(
        'WebRTC',
        'Error playing remote audio',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send function result via data channel
  Future<void> sendFunctionResult({
    required String callId,
    required dynamic result,
  }) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      AppLogger.warn('WebRTC', 'Data channel not ready');
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
  }

  /// Send custom event via data channel
  Future<void> sendEvent(Map<String, dynamic> event) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      AppLogger.warn('WebRTC', 'Data channel not ready');
      return;
    }

    final message = jsonEncode(event);
    _dataChannel!.send(RTCDataChannelMessage(message));
  }

  /// Update connection state
  void _updateConnectionState(ConnectionStateEntity state) {
    _connectionState = state;
    _onConnectionStateChange?.call(state);
  }

  /// Mute/unmute microphone input
  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    if (_localStream == null) {
      AppLogger.warn('WebRTC', 'Microphone stream not available');
      return;
    }

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !isMuted;
    }
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      _stopStatsPolling();

      _onConnectionStateChange = null;
      _onTranscript = null;
      _onFunctionCall = null;
      _onAgentEvent = null;

      // Close data channel
      _dataChannel?.onMessage = null;
      _dataChannel?.onDataChannelState = null;
      _dataChannel?.close();
      _dataChannel = null;

      // Stop local tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream?.dispose();
      _localStream = null;

      // Close peer connection
      _peerConnection?.onTrack = null;
      _peerConnection?.onIceCandidate = null;
      _peerConnection?.onConnectionState = null;
      await _peerConnection?.close();
      _peerConnection = null;

      // Disable speakerphone
      await Helper.setSpeakerphoneOn(false);

      _updateConnectionState(ConnectionStateEntity.disconnected);
      AppLogger.info('WebRTC', 'Disconnected and cleaned up');
    } catch (e, stackTrace) {
      AppLogger.error(
        'WebRTC',
        'Error during disconnect',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _startStatsPolling() {
    if (_statsPollingTimer != null) {
      return;
    }

    _lastWebRtcBytesSent = 0;
    _lastWebRtcBytesReceived = 0;

    _statsPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_collectWebRtcNetworkStats());
    });
  }

  void _stopStatsPolling() {
    _statsPollingTimer?.cancel();
    _statsPollingTimer = null;
    _lastWebRtcBytesSent = 0;
    _lastWebRtcBytesReceived = 0;
  }

  Future<void> _collectWebRtcNetworkStats() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      return;
    }

    try {
      final reports = await peerConnection.getStats();

      var transportSent = 0;
      var transportReceived = 0;
      var hasTransport = false;
      var outboundSent = 0;
      var inboundReceived = 0;

      for (final report in reports) {
        final type = _readReportType(report).toLowerCase();
        final values = _readReportValues(report);

        final bytesSent = _toInt(values['bytesSent'] ?? values['bytes_sent']);
        final bytesReceived = _toInt(
          values['bytesReceived'] ?? values['bytes_received'],
        );

        if (type == 'transport' || type == 'candidate-pair') {
          hasTransport = true;
          transportSent += bytesSent;
          transportReceived += bytesReceived;
          continue;
        }

        if (type.contains('outbound-rtp')) {
          outboundSent += bytesSent;
        }

        if (type.contains('inbound-rtp')) {
          inboundReceived += bytesReceived;
        }
      }

      final totalSent = hasTransport ? transportSent : outboundSent;
      final totalReceived = hasTransport ? transportReceived : inboundReceived;

      if (totalSent <= 0 && totalReceived <= 0) {
        return;
      }

      final deltaSent = totalSent - _lastWebRtcBytesSent;
      final deltaReceived = totalReceived - _lastWebRtcBytesReceived;

      if (deltaSent > 0 || deltaReceived > 0) {
        _runtimeMetrics.addWebRtcTraffic(
          txBytes: deltaSent > 0 ? deltaSent : 0,
          rxBytes: deltaReceived > 0 ? deltaReceived : 0,
        );
      }

      if (totalSent > _lastWebRtcBytesSent) {
        _lastWebRtcBytesSent = totalSent;
      }

      if (totalReceived > _lastWebRtcBytesReceived) {
        _lastWebRtcBytesReceived = totalReceived;
      }
    } catch (_) {
      // Ignore stats polling errors to keep media session stable.
    }
  }

  String _readReportType(dynamic report) {
    try {
      return report.type?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> _readReportValues(dynamic report) {
    dynamic rawValues;

    try {
      rawValues = report.values;
    } catch (_) {
      rawValues = const <String, dynamic>{};
    }

    if (rawValues is Map<String, dynamic>) {
      return rawValues;
    }

    if (rawValues is Map) {
      return Map<String, dynamic>.from(rawValues);
    }

    final result = <String, dynamic>{};
    if (rawValues is List) {
      for (final entry in rawValues) {
        if (entry is Map) {
          final key = entry['name']?.toString();
          if (key == null || key.isEmpty) continue;
          result[key] = entry['value'];
        }
      }
    }

    return result;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
