import RxSwift

extension ObservableType {
  func subscribeOnBackground() -> Observable<E> {
    return self.subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .background))
  }
  
  func observeOnMain() -> Observable<E> {
    return self.observeOn(MainScheduler.instance)
  }
}
