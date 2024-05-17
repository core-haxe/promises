package promises;

class PromiseHelper<T> {
    private var _executing:Bool = false;
    private var _executed:Bool = false;
    private var _waiting:Array<{resolve: ResolveFunction<T>, reject:RejectFunction}> = [];
    private var _onlyExecuteOnce:Bool = false;
    private var _id:String;
    private var _result:T;
    private var _onWaiting:ResolveFunction<T>->RejectFunction->Void;

    public function new(onlyExecuteOnce:Bool = false, id:String = null, onWaiting:ResolveFunction<T>->RejectFunction->Void = null) {
        _onlyExecuteOnce = onlyExecuteOnce;
        _id = id;
        _onWaiting = onWaiting;
    }

    public function resetAccess() {
        _executed = false;
    }

    public function cachedAccess(fn:ResolveFunction<T>->RejectFunction->Void):Promise<T> {
        return new Promise((resolve, reject) -> {
            if (_onlyExecuteOnce && _executed) {
                resolve(_result);
            } else if (_executing && _onWaiting != null) {
                _onWaiting(resolve, reject);
            } else if (_executing) {
                _waiting.push({resolve: resolve, reject: reject});
            } else {
                _executing = true;
                fn((result) -> {
                    _result = result;
                    _executing = false;
                    _executed = true;
                    resolve(result);
                    while (_waiting.length > 0) {
                        _waiting.shift().resolve(result);
                    }
                }, error -> {
                    _executing = false;
                    reject(error);
                    while (_waiting.length > 0) {
                        _waiting.shift().reject(error);
                    }
                });
            }
        });
    }

    public function queuedAccess(fn:ResolveFunction<T>->RejectFunction->Void):Promise<T> {
        return new Promise((resolve, reject) -> {
            if (_onlyExecuteOnce && _executed) {
                resolve(_result);
            } else if (_executing) {
                _waiting.push({resolve: resolve, reject: reject});
            } else {
                _executing = true;
                executeQueuedCall(fn, resolve, reject);
            }
        });
    }

    private function executeQueuedCall(fn:ResolveFunction<T>->RejectFunction->Void, resolve:ResolveFunction<T>, reject:RejectFunction) {
        fn((result) -> {
            _result = result;
            _executed = true;
            resolve(result);
            if (_waiting.length > 0) {
                var item = _waiting.shift();
                executeQueuedCall(fn, item.resolve, item.reject);
            } else {
                //_executing = false;
            }
        }, error -> {
            _executing = false;
            reject(error);
            while (_waiting.length > 0) {
                _waiting.shift().reject(error);
            }
        });
    }
}
