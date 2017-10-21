//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
import Foundation
import RxSwift

private var deallocatedSubjectTriggerContext: UInt8 = 0
private var deallocatedSubjectContext: UInt8 = 0

fileprivate final class DeallocObservable {
  let _subject = ReplaySubject<Void>.create(bufferSize: 1)
  
  init() {
  }
  
  deinit {
    _subject.on(.next(()))
    _subject.on(.completed)
  }
}

extension Reactive where Base: NSObject {
  func synchronized<T>( _ action: () -> T) -> T {
    objc_sync_enter(self.base)
    let result = action()
    objc_sync_exit(self.base)
    return result
  }
}

extension Reactive where Base: NSObject {
  /**
   Observable sequence of object deallocated events.
   
   After object is deallocated one `()` element will be produced and sequence will immediately complete.
   
   - returns: Observable sequence of object deallocated events.
   */
  public var deallocated: Observable<Void> {
    return synchronized {
      if let deallocObservable = objc_getAssociatedObject(base, &deallocatedSubjectContext) as? DeallocObservable {
        return deallocObservable._subject
      }
      
      let deallocObservable = DeallocObservable()
      
      objc_setAssociatedObject(base, &deallocatedSubjectContext, deallocObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return deallocObservable._subject
    }
  }
}
