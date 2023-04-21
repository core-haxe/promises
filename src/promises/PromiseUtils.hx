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
    public static function runSequentially(promises:Array<() -> Promise<Any>>, failFast = true):Promise<Array<Any>> {
        return new Promise((resolve, reject) -> {
            var results = [];
            _runSequentially(promises.copy(), failFast, results, resolve, reject);
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
    public static function runAll(promises:Array<() -> Promise<Any>>, failFast = false):Promise<Array<Any>> {
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
                    results.push(e);
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
        PromiseUtils.runAll([
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
    public static function runAllMapped(promises:Array<{id:String, promise:() -> Promise<Any>}>, failFast = false):Promise<Map<String, Any>> {
        return new Promise((resolve, reject) -> {
            var results:Map<String, Any> = [];
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
                    results.set(id, e);
                    if (failFast == true) {
                        reject(e);
                    } else if (count == 0) {
                        resolve(results);
                    }
                });
            }
        });
    }

    private static function _runSequentially(list:Array<() -> Promise<Any>>, failFast:Bool, results:Array<Any>, resolve:Array<Any>->Void, reject:Any->Void) {
        if (list.length == 0) {
            resolve(results);
            return;
        }

        var fn = list.shift();
        var p = fn();
        p.then(result -> {
            results.push(result);
            _runSequentially(list, failFast, results, resolve, reject);
        }, e -> {
            if (failFast == true) {
                reject(e);
            } else {
                results.push(e);
                _runSequentially(list, failFast, results, resolve, reject);
            }
        });
    }

    public static inline function promisify<T>(param:T):Promise<T> {
        return new Promise((resolve, _) -> resolve(param));
    }
}