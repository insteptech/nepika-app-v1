import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnected(result);
    } catch (e) {
      // If connectivity check fails, assume we're connected to avoid blocking
      return true;
    }
  }

  @override
  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
           result == ConnectivityResult.wifi ||
           result == ConnectivityResult.ethernet;
  }
}
