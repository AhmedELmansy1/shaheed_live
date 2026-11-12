import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/pip_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/match_stream_model.dart';
import '../widgets/stream_report_sheet.dart';
import 'embed_player_screen.dart';

class HlsPlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String serverName;
  final dynamic matchId;
  final String? matchTitle;
  final String? serverId;
  final List<StreamServerModel>? servers;
  final int initialServerIndex;

  const HlsPlayerScreen({
    super.key,
    required this.streamUrl,
    required this.serverName,
    this.matchId,
    this.matchTitle,
    this.serverId,
    this.servers,
    this.initialServerIndex = 0,
  });

  @override
  State<HlsPlayerScreen> createState() => _HlsPlayerScreenState();
}

class _HlsPlayerScreenState extends State<HlsPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isMuted = false;
  bool _isInPipMode = false;
  bool _isAudioMode = false;

  late String _currentStreamUrl;
  late String _currentServerName;
  late int _currentServerIndex;
  final Set<int> _failedServerIndices = {};

  @override
  void initState() {
    super.initState();
    _currentStreamUrl = widget.streamUrl;
    _currentServerName = widget.serverName;
    _currentServerIndex = widget.initialServerIndex;

    _checkAudioMode();
    _initializePlayer();

    PipService.setPipModeListener((inPip) {
      if (mounted) {
        setState(() {
          _isInPipMode = inPip;
          if (inPip) {
            _showControls = false;
          }
        });
      }
    });
    PipService.setAutoPip(true);
  }

  void _checkAudioMode() {
    if (widget.servers != null &&
        _currentServerIndex < widget.servers!.length) {
      final s = widget.servers![_currentServerIndex];
      _isAudioMode = s.isAudioOnly;
    } else {
      _isAudioMode = _currentServerName.contains('صوت') ||
          _currentServerName.contains('راديو');
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    // Auto-detect web embed URLs mistakenly routed to HLS native player
    final clean = _currentStreamUrl.toLowerCase().trim();
    if (!clean.contains('.m3u8') &&
        !clean.contains('.mp4') &&
        (clean.endsWith('.php') ||
            clean.contains('.php?') ||
            clean.endsWith('.html') ||
            clean.contains('.html?') ||
            clean.endsWith('.htm') ||
            clean.contains('.htm?') ||
            clean.contains('embed') ||
            clean.contains('iframe'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EmbedPlayerScreen(
                streamUrl: _currentStreamUrl,
                serverName: _currentServerName,
                matchId: widget.matchId,
                matchTitle: widget.matchTitle ?? 'بث مباشر',
                serverId: widget.serverId ?? 'srv_default',
              ),
            ),
          );
        }
      });
      return;
    }

    try {
      final uri = Uri.parse(_currentStreamUrl);
      _controller?.removeListener(_onControllerUpdate);
      await _controller?.dispose();

      final newController = VideoPlayerController.networkUrl(uri);
      _controller = newController;

      await newController.initialize();
      newController.addListener(_onControllerUpdate);
      await newController.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'تعذر تشغيل هذا السيرفر. جارٍ التحقق من السيرفرات البديلة...';
        });

        // Trigger automatic failover to alternative server if available
        _tryAutoFailover();
      }
    }
  }

  void _tryAutoFailover() {
    final servers = widget.servers;
    if (servers == null || servers.length <= 1) return;

    _failedServerIndices.add(_currentServerIndex);

    // Look for the next untried active server
    for (var i = 0; i < servers.length; i++) {
      final nextIdx = (i + _currentServerIndex + 1) % servers.length;
      if (!_failedServerIndices.contains(nextIdx) && servers[nextIdx].isActive) {
        final nextServer = servers[nextIdx];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ انقطع البث في السيرفر الحالي. جاري التحويل تلقائياً إلى: ${nextServer.name}',
            ),
            backgroundColor: AppColors.vermilion,
            duration: const Duration(seconds: 3),
          ),
        );

        _switchToServer(nextIdx);
        return;
      }
    }
  }

  void _switchToServer(int index) {
    final servers = widget.servers;
    if (servers == null || index < 0 || index >= servers.length) return;

    final target = servers[index];
    setState(() {
      _currentServerIndex = index;
      _currentServerName = target.name;
      _currentStreamUrl = target.streamUrl;
      _isAudioMode = target.isAudioOnly;
    });

    _initializePlayer();
  }

  void _showServerSwitcher() {
    final servers = widget.servers ?? [];
    if (servers.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'اختر سيرفر وجودة البث',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...servers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isCurrent = idx == _currentServerIndex;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isCurrent
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isCurrent ? AppColors.primary : Colors.white60,
                      size: 20,
                    ),
                    title: Row(
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary : Colors.white,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: s.isAudioOnly
                                ? Colors.purple.withValues(alpha: 0.25)
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: s.isAudioOnly
                                  ? Colors.purpleAccent
                                  : AppColors.primary,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            s.qualityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: s.isAudioOnly
                                  ? Colors.purpleAccent
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(ctx).pop();
                      _switchToServer(idx);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    PipService.setAutoPip(false);
    PipService.removePipModeListener();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _enterPictureInPicture() async {
    HapticFeedback.lightImpact();
    setState(() {
      _showControls = false;
    });
    final success = await PipService.enterPip();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'خاصية النافذة العائمة (PiP) غير مدعومة على هذا الجهاز أو الإصدار'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _isInitialized && _controller != null
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0
                      ? _controller!.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(_controller!),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    final hasMultipleServers =
        widget.servers != null && widget.servers!.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              _currentServerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.matchTitle != null)
              Text(
                widget.matchTitle!,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (hasMultipleServers)
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              tooltip: 'تغيير السيرفر والجودة',
              onPressed: _showServerSwitcher,
            ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_rounded,
                color: Colors.white),
            tooltip: 'نافذة عائمة (PiP)',
            onPressed: _enterPictureInPicture,
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.amberAccent),
            tooltip: 'إبلاغ عن عطل في البث',
            onPressed: () {
              StreamReportBottomSheet.show(
                context,
                matchId: widget.matchId ?? 0,
                matchTitle: widget.matchTitle ?? 'مباراة مباشرة',
                serverId: widget.serverId ?? 'hls_server',
                serverName: _currentServerName,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _hasError
              ? _buildErrorWidget()
              : !_isInitialized
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'جاري الاتصال بسيرفر البث المباشر...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    )
                  : _isAudioMode
                      ? _buildAudioRadioVisualizer()
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              _showControls = !_showControls;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio > 0
                                    ? _controller!.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(_controller!),
                              ),
                              if (_showControls) _buildControlsOverlay(),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildAudioRadioVisualizer() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0F172A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withValues(alpha: 0.15),
              border: Border.all(color: Colors.purpleAccent, width: 2),
            ),
            child: const Icon(
              Icons.radio_rounded,
              color: Colors.purpleAccent,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'إذاعة المباراة الصوتية المباشرة (راديو)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'وضع توفير فائق للبيانات والبطارية · استمع للمباراة والتعليق في الخلفية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 48,
                icon: Icon(
                  _controller?.value.isPlaying == true
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 32,
                icon: Icon(
                  _isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white70,
                ),
                onPressed: _toggleMute,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (_controller == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'مباشر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center Play/Pause
            IconButton(
              iconSize: 56,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
              ),
              onPressed: _togglePlayPause,
            ),

            // Bottom Progress Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.live),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => EmbedPlayerScreen(
                        streamUrl: _currentStreamUrl,
                        serverName: _currentServerName,
                        matchId: widget.matchId,
                        matchTitle: widget.matchTitle ?? 'بث مباشر',
                        serverId: widget.serverId ?? 'srv_default',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.web_rounded),
                label: const Text('تشغيل كمشغل ويب (Embed)'),
              ),
              if (widget.servers != null && widget.servers!.length > 1) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showServerSwitcher,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('تبديل السيرفر'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
