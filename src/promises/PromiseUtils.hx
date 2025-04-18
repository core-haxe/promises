package promises;

class PromiseUtils {
    /*
    Use .bind to return functions that create a promise, eg:
        PromiseUtils.runSequentially([
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(111),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(222),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(333),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(444),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(555)
        ]).then(results -> {
            trace("all complete", results);
        }, error -> {
            trace("error", error);
        });
    */
    public static function runSequentially<T>(promises:Array<() -> Promise<T>>, failFast = true, progressCallback:Int->Int->Void = null):Promise<Array<T>> {
        return new Promise((resolve, reject) -> {
            var results:Array<T> = [];
            if (progressCallback != null) {
                progressCallback(0, promises.length);
            }
            _runSequentially(promises.copy(), failFast, results, resolve, reject, progressCallback);
        });
    }

    /*
    Use .bind to return functions that create a promise, eg:
        PromiseUtils.runAll([
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(111),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(222),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(333),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(444),
            someFunctionThatReturnsAPromiseAndTakesAnInt.bind(555)
        ]).then(results -> {
            trace("all complete", results);
        }, error -> {
            trace("error", error);
        });
    */
    public static function runAll<T>(promises:Array<() -> Promise<T>>, failFast = false, excludeFailures:Bool = false):Promise<Array<T>> {
        return new Promise((resolve, reject) -> {
            if (promises.length == 0) {
                resolve([]);
                return;
            }
            var results = [];
            var count = promises.length;

            for (fn in promises) {
                var p = fn();
                p.then(result -> {
                    count--;
                    results.push(result);
                    if (count == 0) {
                        resolve(results);
                    }
                }, e -> {
                    count--;
                    if (!excludeFailures) {
                        results.push(e);
                    }
                    if (failFast == true) {
                        reject(e);
                    } else if (count == 0) {
                        resolve(results);
                    }
                });
            }
        });
    }

    /*
    Use .bind to return functions that create a promise, eg:
        PromiseUtils.runAllMapped([
            {id: "id1", promise: someFunctionThatReturnsAPromiseAndTakesAnInt.bind(111)},
            {id: "id2", promise: someFunctionThatReturnsAPromiseAndTakesAnInt.bind(222)},
            {id: "id3", promise: someFunctionThatReturnsAPromiseAndTakesAnInt.bind(333)},
            {id: "id4", promise: someFunctionThatReturnsAPromiseAndTakesAnInt.bind(444)},
            {id: "id5", promise: someFunctionThatReturnsAPromiseAndTakesAnInt.bind(555)}
        ]).then(results -> {
            trace("all complete", results);
        }, error -> {
            trace("error", error);
        });
    */
    public static function runAllMapped<T>(promises:Array<{id:String, promise:() -> Promise<T>}>, failFast = false, excludeFailures:Bool = false):Promise<Map<String, T>> {
        return new Promise((resolve, reject) -> {
            var results:Map<String, T> = [];
            if (promises.length == 0) {
                resolve(results);
                return;
            }
            var count = promises.length;

            for (item in promises) {
                var fn = item.promise;
                var id = item.id;
                var p = fn();
                p.then(result -> {
                    count--;
                    results.set(id, result);
                    if (count == 0) {
                        resolve(results);
                    }
                }, e -> {
                    count--;
                    if (!excludeFailures) {
                        results.set(id, e);
                    }
                    if (failFast == true) {
                        reject(e);
                    } else if (count == 0) {
                        resolve(results);
                    }
                });
            }
        });
    }

    private static function _runSequentially<T>(list:Array<() -> Promise<T>>, failFast:Bool, results:Array<T>, resolve:Array<T>->Void, reject:Any->Void, progressCallback:Int->Int->Void) {
        if (list.length == 0) {
            resolve(results);
            return;
        }

        var fn = list.shift();
        var p = fn();
        p.then(result -> {
            results.push(result);

            if (progressCallback != null) {
                var max = (results.length + list.length);
                var current = results.length;
                progressCallback(current, max);
            }
    
            _runSequentially(list, failFast, results, resolve, reject, progressCallback);
        }, e -> {
            if (failFast == true) {
                reject(e);
            } else {
                results.push(e);

                if (progressCallback != null) {
                    var max = (results.length + list.length);
                    var current = results.length;
                    progressCallback(current, max);
                }
    
                _runSequentially(list, failFast, results, resolve, reject, progressCallback);
            }
        });
    }

    public static function wait(amountMS:Int) {
        return new Promise((resolve, reject) -> {
            haxe.Timer.delay(() -> {
                resolve(true);
            }, amountMS);
        });
    }

    public static inline function promisify<T>(param:T):Promise<T> {
        return new Promise((resolve, _) -> resolve(param));
    }
}