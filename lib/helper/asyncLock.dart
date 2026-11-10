class AsyncLock {
  Future? _lock;

  Future<void> run(Future<void> Function() task) async {
    // 如果正在执行，等待上一个任务完成
    while (_lock != null) {
      await _lock;
    }
    try {
      _lock = task();
      await _lock;
    } finally {
      _lock = null;
    }
  }
}
