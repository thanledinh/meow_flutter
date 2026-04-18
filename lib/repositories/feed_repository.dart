import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../api/post_api.dart';
import '../api/feed_api.dart';
import '../api/local_cache.dart';

class FeedRepository extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  
  dynamic _nextCursor;
  bool _hasMore = true;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  static const String feedCacheKey = 'home_feed_v1';

  Future<void> fetchFeed({bool refresh = false}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }

    // 1. Offline-first: Load from Local Cache
    if (!refresh && _posts.isEmpty) {
      final cached = await LocalCache.load(feedCacheKey);
      if (cached != null && cached['data'] is List) {
        final list = cached['data'] as List;
        _posts = list.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
        _isLoading = false;
        notifyListeners();
      }
    }

    if (_posts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // 2. Fetch API ngầm để lấy data mới
    final res = await PostApi.getFeed(cursor: _nextCursor, limit: 10);
    
    if (res.success) {
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data != null) {
        final newPostsRaw = data['posts'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        
        _nextCursor = pagination?['nextCursor'];
        _hasMore = pagination?['hasMore'] == true;
        
        final newPosts = newPostsRaw.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();

        if (refresh || _nextCursor == null) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }
        _error = null;

        // Lưu cache trang đầu tiên
        if (_nextCursor == null || refresh) {
          // Chỉ lấy tối đa 20 bài cho nhẹ
          final cacheData = newPostsRaw.take(20).toList();
          await LocalCache.save(feedCacheKey, jsonEncode({'data': cacheData}));
        }
      }
    } else {
      _error = res.error ?? 'Lỗi tải Feed';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();

    final res = await PostApi.getFeed(cursor: _nextCursor, limit: 10);
    
    if (res.success) {
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data != null) {
        final newPostsRaw = data['posts'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        
        _nextCursor = pagination?['nextCursor'];
        _hasMore = pagination?['hasMore'] == true;
        
        final newPosts = newPostsRaw.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList();
        _posts.addAll(newPosts);
      }
    }
    
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = _posts[idx];
    final wasLiked = post.isLiked;
    final prevCount = post.likeCount;

    // Optimistic Update UI
    _posts[idx] = _copyPostWith(post, isLiked: !wasLiked, likeCount: wasLiked ? prevCount - 1 : prevCount + 1);
    notifyListeners();

    try {
      final res = await FeedApi.like(postId);
      if (res.success) {
        final data = (res.data as Map?)?['data'] as Map<String, dynamic>?;
        if (data != null) {
          // Cập nhật giá trị thực từ server
          _posts[idx] = _copyPostWith(
            _posts[idx],
            isLiked: data['liked'] as bool? ?? !wasLiked,
            likeCount: data['likeCount'] as int? ?? prevCount,
          );
          notifyListeners();
        }
      } else {
        // Rollback
        _posts[idx] = _copyPostWith(post, isLiked: wasLiked, likeCount: prevCount);
        notifyListeners();
      }
    } catch (_) {
      // Rollback
      _posts[idx] = _copyPostWith(post, isLiked: wasLiked, likeCount: prevCount);
      notifyListeners();
    }
  }
  
  void incrementComment(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx] = _copyPostWith(_posts[idx], commentCount: _posts[idx].commentCount + 1);
      notifyListeners();
    }
  }

  PostModel _copyPostWith(PostModel p, {bool? isLiked, int? likeCount, int? commentCount}) {
    // Thủ thuật clone PostModel do chưa cấu hình Freezed copyWith
    // Sẽ tạo một instance mới với các thông số cập nhật
    return PostModel(
      id: p.id,
      author: p.author,
      pet: p.pet,
      content: p.content,
      mediaUrls: p.mediaUrls,
      likeCount: likeCount ?? p.likeCount,
      commentCount: commentCount ?? p.commentCount,
      isLiked: isLiked ?? p.isLiked,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      checkInLocation: p.checkInLocation,
      petTags: p.petTags,
    );
  }
}
