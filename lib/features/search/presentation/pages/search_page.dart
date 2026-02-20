import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../performance/data/models/performance_summary.dart';
import '../../../performance/presentation/bloc/performance_bloc.dart';
import '../../../performance/presentation/bloc/performance_event.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/usecases/search_hotels.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final dataSource = SearchRemoteDataSourceImpl();
        final repository = SearchRepositoryImpl(dataSource);
        final useCase = SearchHotels(repository);
        return SearchBloc(searchHotels: useCase)
          ..add(const SearchHotelsEvent()); // Load all suggestions initially
      },
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  const _SearchPageContent();

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _sessionStarted = false;
  bool _searchStepStarted = false;
  String _lastSearchValue = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureSessionStarted() {
    if (_sessionStarted) return;
    _sessionStarted = true;
    context.read<PerformanceBloc>().add(
      const StartSession(method: InteractionMethod.gui),
    );
  }

  void _startSearchInputIfNeeded() {
    if (_searchStepStarted) return;
    _searchStepStarted = true;
    context.read<PerformanceBloc>().add(
      const StartStep(PerformanceStep.search),
    );
  }

  void _endSearchInputIfNeeded() {
    if (!_searchStepStarted) return;
    _searchStepStarted = false;
    context.read<PerformanceBloc>().add(const EndStep(PerformanceStep.search));
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      // Show all suggestions
      context.read<SearchBloc>().add(const SearchHotelsEvent());
    } else {
      // Filter suggestions
      context.read<SearchBloc>().add(
        SearchHotelsEvent(query: query, location: query),
      );
    }
  }

  void _selectLocation(String locationOrHotelName) {
    _ensureSessionStarted();
    context.read<PerformanceBloc>().add(const AddClick());
    context.read<PerformanceBloc>().add(
      UpdateSearchedLocation(locationOrHotelName),
    );
    _endSearchInputIfNeeded();
    // Return selected value to home page
    context.pop(locationOrHotelName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pilih Lokasi atau Hotel',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Input Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onTap: () {
                _ensureSessionStarted();
                _startSearchInputIfNeeded();
              },
              decoration: InputDecoration(
                hintText: 'Cari kota atau nama hotel...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ensureSessionStarted();
                          context.read<PerformanceBloc>().add(const AddClick());
                          _searchController.clear();
                          _lastSearchValue = '';
                          _performSearch('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                _ensureSessionStarted();
                _startSearchInputIfNeeded();
                if (_lastSearchValue.isNotEmpty &&
                    value.length < _lastSearchValue.length) {
                  context.read<PerformanceBloc>().add(const AddCorrection());
                }
                _lastSearchValue = value;
                _performSearch(value);
                setState(() {});
              },
            ),
          ),
          // Suggestions List
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is SearchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kesalahan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (state is SearchEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ditemukan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba kata kunci lain',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SearchLoaded) {
                  // Create unique list of locations and hotel names
                  final suggestions = <String>{};

                  for (final hotel in state.hotels) {
                    suggestions.add(hotel.location);
                    suggestions.add(hotel.name);
                  }

                  final sortedSuggestions = suggestions.toList()..sort();

                  return NotificationListener<ScrollEndNotification>(
                    onNotification: (notification) {
                      _ensureSessionStarted();
                      context.read<PerformanceBloc>().add(const AddScroll());
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: sortedSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = sortedSuggestions[index];
                        final isLocation = state.hotels.any(
                          (hotel) => hotel.location == suggestion,
                        );

                        return ListTile(
                          leading: Icon(
                            isLocation ? Icons.location_on : Icons.hotel,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            isLocation ? 'Lokasi' : 'Hotel',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => _selectLocation(suggestion),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  );
                }

                // Initial state - show empty state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cari lokasi atau hotel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan nama kota atau hotel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
