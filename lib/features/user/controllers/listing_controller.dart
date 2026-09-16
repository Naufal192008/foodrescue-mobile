import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../data/listing_repository.dart';

final listingRepositoryProvider =
    Provider<ListingRepository>((ref) => ListingRepository());

class ListingState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? selectedCategory;
  final String searchQuery;
  final List<FoodListingModel> listings;
  final int page;
  final bool hasMore;

  ListingState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
    this.listings = const [],
    this.page = 1,
    this.hasMore = true,
  });

  ListingState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<FoodListingModel>? listings,
    int? page,
    bool? hasMore,
    bool clearError = false,
  }) {
    return ListingState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      selectedCategory: selectedCategory,
      searchQuery: searchQuery,
      listings: listings ?? this.listings,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ListingController extends StateNotifier<ListingState> {
  final ListingRepository _repo;

  ListingController(this._repo) : super(ListingState());

  /// Kategori unik dari listing yang sudah dimuat (untuk filter chips).
  List<String> get categories {
    final set = <String>{};
    for (final l in state.listings) {
      if (l.category.isNotEmpty) set.add(l.category);
    }
    return set.toList()..sort();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getListings(
        category: state.selectedCategory,
        search: state.searchQuery,
      );
      state = state.copyWith(
        isLoading: false,
        listings: result.data,
        page: result.page,
        hasMore: result.page < result.totalPages,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.page + 1;
      final result = await _repo.getListings(
        page: next,
        category: state.selectedCategory,
        search: state.searchQuery,
      );
      state = state.copyWith(
        isLoadingMore: false,
        listings: [...state.listings, ...result.data],
        page: result.page,
        hasMore: result.page < result.totalPages,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void selectCategory(String? category) {
    state = ListingState(
      selectedCategory: category,
      searchQuery: state.searchQuery,
    );
    loadInitial();
  }

  void setSearch(String query) {
    state = ListingState(
      selectedCategory: state.selectedCategory,
      searchQuery: query,
    );
    loadInitial();
  }
}

final listingControllerProvider = StateNotifierProvider<ListingController, ListingState>(
  (ref) => ListingController(ref.watch(listingRepositoryProvider)),
);