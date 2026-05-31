import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OptimizedBlocBuilder<B extends StateStreamable<S>, S, T>
    extends StatelessWidget {
  const OptimizedBlocBuilder({
    super.key,
    required this.selector,
    required this.builder,
    this.buildWhen,
  });

  final T Function(S) selector;
  final Widget Function(BuildContext, T) builder;
  final bool Function(S, S)? buildWhen;

  @override
  Widget build(BuildContext context) {
    if (buildWhen != null) {
      return BlocBuilder<B, S>(
        buildWhen: buildWhen,
        builder: (context, state) => builder(context, selector(state)),
      );
    }

    return BlocSelector<B, S, T>(selector: selector, builder: builder);
  }
}

/// Mixin for common buildWhen conditions
mixin BlocBuildWhenMixin {
  /// Only rebuild when the state type changes
  bool buildWhenStateTypeChanges<S>(S previous, S current) {
    return previous.runtimeType != current.runtimeType;
  }

  /// Only rebuild when specific property changes
  bool buildWhenPropertyChanges<S, T>(
    S previous,
    S current,
    T Function(S) selector,
  ) {
    return selector(previous) != selector(current);
  }

  /// Combine multiple buildWhen conditions with OR logic
  bool buildWhenAny<S>(
    S previous,
    S current,
    List<bool Function(S, S)> conditions,
  ) {
    return conditions.any((condition) => condition(previous, current));
  }

  /// Combine multiple buildWhen conditions with AND logic
  bool buildWhenAll<S>(
    S previous,
    S current,
    List<bool Function(S, S)> conditions,
  ) {
    return conditions.every((condition) => condition(previous, current));
  }
}
