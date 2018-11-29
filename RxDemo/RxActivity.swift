//
//  RxActivity.swift
//  RxDemo
//
//  Created by Trinity on 2018/11/29.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class RxActivity: NSObject, ObservableConvertibleType {
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
    
    func asObservable() -> Observable<RxActivity.E> {
        return isActivity
    }
    
    fileprivate func trackActivity<O: ObservableConvertibleType>(of source: O) -> Observable<O.E> {
        return Observable.using({ () -> RxActivityToken<O.E> in
            self.increment()
            return RxActivityToken(source: source.asObservable(), disposeAction: self.increment)
        }, observableFactory: { token in
            return token.asObservable()
        })
    }
}

class RxActivityToken<E>: NSObject, ObservableConvertibleType, Disposable {
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
    func trackActivity(by activity: RxActivity) -> Observable<E> {
        return activity.trackActivity(of: self)
    }
}
