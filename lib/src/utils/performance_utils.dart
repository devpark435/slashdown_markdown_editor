import 'dart:developer' as developer;

/// 성능 측정 및 최적화 유틸리티
class PerformanceUtils {
  static final Map<String, List<Duration>> _measurements = {};
  static bool _isEnabled = false;

  /// 성능 측정 활성화/비활성화
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _measurements.clear();
    }
  }

  /// 실행 시간 측정
  static T measureTime<T>(String operation, T Function() function) {
    if (!_isEnabled) {
      return function();
    }

    final stopwatch = Stopwatch()..start();
    final result = function();
    stopwatch.stop();

    _measurements.putIfAbsent(operation, () => []).add(stopwatch.elapsed);

    developer.log(
      'Performance: $operation took ${stopwatch.elapsedMilliseconds}ms',
      name: 'SlashdownEditor',
    );

    return result;
  }

  /// 비동기 실행 시간 측정
  static Future<T> measureTimeAsync<T>(
      String operation, Future<T> Function() function) async {
    if (!_isEnabled) {
      return await function();
    }

    final stopwatch = Stopwatch()..start();
    final result = await function();
    stopwatch.stop();

    _measurements.putIfAbsent(operation, () => []).add(stopwatch.elapsed);

    developer.log(
      'Performance: $operation took ${stopwatch.elapsedMilliseconds}ms',
      name: 'SlashdownEditor',
    );

    return result;
  }

  /// 평균 실행 시간 조회
  static Duration? getAverageTime(String operation) {
    final times = _measurements[operation];
    if (times == null || times.isEmpty) return null;

    final totalMicroseconds = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicroseconds ~/ times.length);
  }

  /// 모든 측정 결과 조회
  static Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};

    for (final entry in _measurements.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        final totalMicros =
            times.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
        final avgMicros = totalMicros ~/ times.length;
        final minMicros =
            times.map((d) => d.inMicroseconds).reduce((a, b) => a < b ? a : b);
        final maxMicros =
            times.map((d) => d.inMicroseconds).reduce((a, b) => a > b ? a : b);

        stats[entry.key] = PerformanceStats(
          operation: entry.key,
          callCount: times.length,
          averageTime: Duration(microseconds: avgMicros),
          minTime: Duration(microseconds: minMicros),
          maxTime: Duration(microseconds: maxMicros),
          totalTime: Duration(microseconds: totalMicros),
        );
      }
    }

    return stats;
  }

  /// 측정 결과 초기화
  static void clearStats() {
    _measurements.clear();
  }

  /// 성능 리포트 출력
  static void printReport() {
    if (!_isEnabled || _measurements.isEmpty) {
      developer.log('Performance measurement is disabled or no data available',
          name: 'SlashdownEditor');
      return;
    }

    final stats = getAllStats();
    developer.log('=== Performance Report ===', name: 'SlashdownEditor');

    for (final stat in stats.values) {
      developer.log(
        '${stat.operation}: ${stat.callCount} calls, avg: ${stat.averageTime.inMilliseconds}ms, '
        'min: ${stat.minTime.inMilliseconds}ms, max: ${stat.maxTime.inMilliseconds}ms',
        name: 'SlashdownEditor',
      );
    }
  }
}

/// 성능 통계 정보
class PerformanceStats {
  final String operation;
  final int callCount;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final Duration totalTime;

  const PerformanceStats({
    required this.operation,
    required this.callCount,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.totalTime,
  });

  @override
  String toString() {
    return 'PerformanceStats{$operation: ${callCount}x, avg: ${averageTime.inMilliseconds}ms}';
  }
}

/// 메모리 최적화 관련 유틸리티
class MemoryUtils {
  /// WeakReference 기반 캐시 (메모리 누수 방지)
  static final Map<String, WeakReference<Object>> _cache = {};

  /// 캐시에서 값 조회
  static T? getCached<T extends Object>(String key) {
    final ref = _cache[key];
    return ref?.target as T?;
  }

  /// 캐시에 값 저장
  static void setCached<T extends Object>(String key, T value) {
    _cache[key] = WeakReference(value);
  }

  /// 캐시 정리 (가비지 컬렉션된 항목 제거)
  static void cleanupCache() {
    _cache.removeWhere((key, ref) => ref.target == null);
  }

  /// 캐시 크기 조회
  static int getCacheSize() {
    cleanupCache();
    return _cache.length;
  }
}

/// 렌더링 최적화 유틸리티
class RenderUtils {
  /// 디바운싱을 위한 타이머 맵
  static final Map<String, DateTime> _lastCalls = {};

  /// 디바운스 함수 (과도한 호출 방지)
  static bool shouldExecute(String key, Duration threshold) {
    final now = DateTime.now();
    final lastCall = _lastCalls[key];

    if (lastCall == null || now.difference(lastCall) >= threshold) {
      _lastCalls[key] = now;
      return true;
    }

    return false;
  }

  /// 쓰로틀링 함수 (최대 실행 빈도 제한)
  static bool shouldThrottle(String key, Duration interval) {
    return shouldExecute(key, interval);
  }

  /// 배치 업데이트를 위한 큐
  static final Map<String, List<VoidCallback>> _batchQueues = {};

  /// 배치에 작업 추가
  static void addToBatch(String batchKey, VoidCallback callback) {
    _batchQueues.putIfAbsent(batchKey, () => []).add(callback);
  }

  /// 배치 실행
  static void executeBatch(String batchKey) {
    final callbacks = _batchQueues.remove(batchKey);
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback();
      }
    }
  }
}

/// 콜백 타입 정의
typedef VoidCallback = void Function();
