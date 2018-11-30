//
//  RXActivity.swift
//  RxDemo
//
//  Created by Trinity on 2018/11/29.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/**
 * Monitor sequence computation.
 * If there is least on sequence computation in progress, `true` will be sent.
 */
class RXActivity: NSObject, ObservableConvertibleType {
    typealias E = Bool

    private var relay = BehaviorRelay(value: 0)
    private var isActivity: Observable<Bool>
    private var lock = NSRecursiveLock()
    
    override init() {
        isActivity = relay
            .map { $0 > 0 }
            .distinctUntilChanged()

        super.init()
    }
    
    private func increment(){
        lock.lock()
        defer { lock.unlock() }

        relay.accept(relay.value + 1)
    }
    
    private func decrement(){
        lock.lock()
        defer { lock.unlock() }
        
        relay.accept(relay.value - 1)
    }
    
    func asObservable() -> Observable<RXActivity.E> {
        return isActivity
    }
    
    fileprivate func trackActivity<O: ObservableConvertibleType>(of source: O) -> Observable<O.E> {
        return Observable.using({ () -> RXActivityToken<O.E> in
            self.increment()
            return RXActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }, observableFactory: { token in
            return token.asObservable()
        })
    }
}

class RXActivityToken<E>: NSObject, ObservableConvertibleType, Disposable {
    private var source: Observable<E>
    private var disposable: Cancelable
    
    init(source: Observable<E>, disposeAction: @escaping () -> ()) {
        self.source = source
        self.disposable = Disposables.create(with: disposeAction)
    }
    
    func dispose() {
        disposable.dispose()
    }
    
    func asObservable() -> Observable<E> {
        return source
    }
}

extension ObservableConvertibleType {
    func trackActivity(by activity: RXActivity) -> Observable<E> {
        return activity.trackActivity(of: self)
    }
}
