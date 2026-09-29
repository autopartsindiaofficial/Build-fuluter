import NetInfo, { NetInfoState } from '@react-native-community/netinfo';

type NetworkListener = (isConnected: boolean, isInternetReachable: boolean) => void;

class NetworkConnectivityManager {
  private isConnected: boolean = true;
  private isInternetReachable: boolean = true;
  private listeners = new Set<NetworkListener>();
  private unsubscribeNetInfo: (() => void) | null = null;

  constructor() {
    this.init();
  }

  private init() {
    this.unsubscribeNetInfo = NetInfo.addEventListener((state: NetInfoState) => {
      this.isConnected = Boolean(state.isConnected);
      this.isInternetReachable = Boolean(state.isInternetReachable ?? state.isConnected);
      this.notifyListeners();
    });

    NetInfo.fetch().then((state) => {
      this.isConnected = Boolean(state.isConnected);
      this.isInternetReachable = Boolean(state.isInternetReachable ?? state.isConnected);
    });
  }

  public getOnlineStatus(): { isConnected: boolean; isInternetReachable: boolean } {
    return {
      isConnected: this.isConnected,
      isInternetReachable: this.isInternetReachable,
    };
  }

  public subscribe(listener: NetworkListener): () => void {
    this.listeners.add(listener);
    // Initial call
    listener(this.isConnected, this.isInternetReachable);

    return () => {
      this.listeners.delete(listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach((listener) => {
      try {
        listener(this.isConnected, this.isInternetReachable);
      } catch (_) {}
    });
  }

  public destroy() {
    if (this.unsubscribeNetInfo) {
      this.unsubscribeNetInfo();
    }
    this.listeners.clear();
  }
}

export const networkManager = new NetworkConnectivityManager();
