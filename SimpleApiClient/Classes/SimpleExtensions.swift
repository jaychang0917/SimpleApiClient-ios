import RxSwift

// MARK: - Retry operators

public extension ObservableType {
  public func retry(delay: TimeInterval, maxRetryCount: Int = Int.max) -> Observable<E> {
    return asObservable().retryWhen { errorObservable in
      errorObservable
        .scan((currentCount: 0, error: Error?.none), accumulator: { result, error in
          return (currentCount: result.currentCount + 1, error: error)
        })
        .flatMap { (currentCount, error) in
          return ((currentCount > maxRetryCount) ? Observable.error(error!) : Observable.just(()))
            .delay(delay, scheduler: MainScheduler.instance)
      }
    }
  }
  
  public func retry(exponentialDelay delay: TimeInterval, maxRetryCount: Int = Int.max) -> Observable<E> {
    return asObservable().retryWhen { errorObservable in
      errorObservable
        .scan((currentCount: 0, error: Error?.none), accumulator: { result, error in
          return (currentCount: result.currentCount + 1, error: error)
        })
        .flatMap { (currentCount, error) in
          return ((currentCount > maxRetryCount) ? Observable.error(error!) : Observable.just(()))
            .delay(pow(delay, Double(currentCount)), scheduler: MainScheduler.instance)
      }
    }
  }
}

// MARK: - Serial & Parallel operators

public extension SimpleApiClient {
  public static func all<O: ObservableType>(_ calls: O...) -> Observable<[Any]> where O.E == Any {
    return Observable.zip(calls) { objects in objects }
  }
}

public extension ObservableType {
  public func then<O: ObservableType>(_ call: @escaping (E) -> O) -> Observable<O.E> {
    return flatMap(call)
  }
}

public extension ObservableType {
  /* todo
  public func thenAll<C: Collection>(_ calls: @escaping (E) -> C) -> Observable<[Any]> where C.Iterator.Element: ObservableType {
    return flatMap { input in Observable.zip(calls(input)) { objects in objects }
    }
  }
  */
  
  public func thenAll<O1: ObservableType, O2: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2)) -> Observable<(O1.E, O2.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1) { ($0, $1) }
        }() as Observable<(O1.E, O2.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3)) -> Observable<(O1.E, O2.E, O3.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2) { ($0, $1, $2) }
        }() as Observable<(O1.E, O2.E, O3.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType, O4: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3, O4)) -> Observable<(O1.E, O2.E, O3.E, O4.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2, results.3) { ($0, $1, $2, $3) }
        }() as Observable<(O1.E, O2.E, O3.E, O4.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType, O4: ObservableType, O5: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3, O4, O5)) -> Observable<(O1.E, O2.E, O3.E, O4.E, O5.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2, results.3, results.4) { ($0, $1, $2, $3, $4) }
        }() as Observable<(O1.E, O2.E, O3.E, O4.E, O5.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType, O4: ObservableType, O5: ObservableType, O6: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3, O4, O5, O6)) -> Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2, results.3, results.4, results.5) { ($0, $1, $2, $3, $4, $5) }
        }() as Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType, O4: ObservableType, O5: ObservableType, O6: ObservableType, O7: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3, O4, O5, O6, O7)) -> Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E, O7.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2, results.3, results.4, results.5, results.6) { ($0, $1, $2, $3, $4, $5, $6) }
        }() as Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E, O7.E)>
    }
  }
  
  public func thenAll<O1: ObservableType, O2: ObservableType, O3: ObservableType, O4: ObservableType, O5: ObservableType, O6: ObservableType, O7: ObservableType, O8: ObservableType>(
    _ calls: @escaping (E) -> (O1, O2, O3, O4, O5, O6, O7, O8)) -> Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E, O7.E, O8.E)> {
    return flatMap { input in
      return {
        let results = calls(input)
        return Observable.zip(results.0, results.1, results.2, results.3, results.4, results.5, results.6, results.7) { ($0, $1, $2, $3, $4, $5, $6, $7) }
        }() as Observable<(O1.E, O2.E, O3.E, O4.E, O5.E, O6.E, O7.E, O8.E)>
    }
  }
}

// MARK: -

public extension ObservableType {
  public func cancel(when deallocated: Observable<Void>) -> ObservableProxy<E> {
    return ObservableProxy(asObservable().takeUntil(deallocated))
  }
}

// MARK: -

public extension ObservableType {
  @discardableResult
  public func observe(onStart: @escaping () -> Void = {}, onEnd: @escaping () -> Void = {}, onSuccess: @escaping (E) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) -> SimpleApiClient.Cancelable {
    let doOn = self.do(onSubscribe: onStart, onDispose: onEnd).subscribe(onNext: { value in  onSuccess(value) }, onError: { errorResponse in
      ErrorConsumer(errorResponse: errorResponse as! ErrorResponse, errorHandler: onError).accept() })
    return SimpleApiClient.Cancelable(Disposables.create([doOn]))
  }
}
