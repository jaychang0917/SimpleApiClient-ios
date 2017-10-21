import Foundation
import RxSwift

public class ObservableProxy<E> {
  private let sourceObservable: Observable<E>
  
  init(_ sourceObservable: Observable<E>) {
    self.sourceObservable = sourceObservable
  }
  
  @discardableResult
  public func observe(onStart: @escaping () -> Void = {}, onEnd: @escaping () -> Void = {}, onSuccess: @escaping (E) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) -> SimpleApiClient.Cancelable {
    return sourceObservable.observe(onStart: onStart, onEnd: onEnd, onSuccess: onSuccess, onError: onError)
  }
}
