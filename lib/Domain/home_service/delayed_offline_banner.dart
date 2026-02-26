import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_management_pwa/app_contants.dart';


class DelayedOfflineBanner extends StatefulWidget {
  final bool isFromCache;

  const DelayedOfflineBanner({Key? key, required this.isFromCache}) : super(key: key);

  @override
  State<DelayedOfflineBanner> createState() => _DelayedOfflineBannerState();
}

class _DelayedOfflineBannerState extends State<DelayedOfflineBanner> {
  bool _showBanner = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _evaluateCache(widget.isFromCache);
  }

  @override
  void didUpdateWidget(covariant DelayedOfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFromCache != widget.isFromCache) {
      _evaluateCache(widget.isFromCache);
    }
  }

  void _evaluateCache(bool isFromCache) {
    if (isFromCache) {
      // Dacă primim date din cache, pornim un cronometru de 1.5 secunde
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showBanner = true);
        }
      });
    } else {
      // Dacă au venit datele de pe server real, anulăm cronometrul imediat!
      _timer?.cancel();
      if (_showBanner) {
        setState(() => _showBanner = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    // Aici pui design-ul tău de banner offline
    return Container(
      width: double.infinity,
      color: AppColors.bordeaux,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Text(
        'Sunteți offline.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}