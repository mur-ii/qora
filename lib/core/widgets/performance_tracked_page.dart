import 'package:flutter/material.dart';

import '../services/performance_sampler.dart';

class PerformanceTrackedPage extends StatefulWidget {
  final String pageName;
  final Widget child;

  const PerformanceTrackedPage({
    super.key,
    required this.pageName,
    required this.child,
  });

  @override
  State<PerformanceTrackedPage> createState() => _PerformanceTrackedPageState();
}

class _PerformanceTrackedPageState extends State<PerformanceTrackedPage> {
  late final PerformanceSampler _sampler;

  @override
  void initState() {
    super.initState();
    _sampler = PerformanceSampler(pageName: widget.pageName);
    _sampler.start();
  }

  @override
  void dispose() {
    _sampler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
