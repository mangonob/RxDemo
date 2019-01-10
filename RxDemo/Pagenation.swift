//
//  Pagenation.swift
//  RxDemo
//
//  Created by 高炼 on 2019/1/4.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire

class Mock {
    typealias ElementFactory = () -> Any
    private var factory: ElementFactory
    
    init(_ factory: @escaping ElementFactory) {
        self.factory = factory
    }
    
    func getElements() -> Any {
        return factory()
    }
}

extension Mock: ReactiveCompatible { }

extension Reactive where Base: Mock {
    func request<E: Any>(type: E.Type) -> Observable<E> {
        return Observable<E>.create { [weak base] (subscriber) -> Disposable in
            let operation = BlockOperation(block: {
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                    if let element = base?.getElements() as? E {
                        subscriber.onNext(element)
                    }
                    
                    subscriber.onCompleted()
                })
            })
            
            operation.start()
            
            return Disposables.create {
                operation.cancel()
            }
        }
    }
}

class PagenationState {
    func setState<E: Any>(_ pagenation: Pagenation<E>?, state: PagenationState?) {
        if let state = state {
            pagenation?.state.accept(state)
        }
        
        state?.become(pagenation)
    }
    
    func become<E>(_ pagenation: Pagenation<E>?) {
    }

    func reloadData<E>(_ pagenation: Pagenation<E>) {
        setState(pagenation, state: PagenationStateReloading.shared)
        
        pagenation.createElementsObservable().subscribe(onNext: { [weak pagenation] (contents) in
            self.setState(pagenation, state: PagenationStateInitial.shared)
            self.setState(pagenation, state: contents.isEmpty ? PagenationStateCompleted.shared : PagenationStateFetchedContents(contents))
            }, onError: { [weak pagenation] (_) in
                self.setState(pagenation, state: PagenationStateError.shared)
        }).disposed(by: pagenation.disposeBag)
    }
    
    func loadMoreData<E>(_ pagenation: Pagenation<E>) {
        setState(pagenation, state: PagenationStateLoadingMore.shared)
        
        pagenation.createElementsObservable().subscribe(onNext: { [weak pagenation] (contents) in
            self.setState(pagenation, state: contents.isEmpty ? PagenationStateCompleted.shared : PagenationStateFetchedContents(contents))
            }, onError: { [weak pagenation] (_) in
                self.setState(pagenation, state: PagenationStateError.shared)
        }).disposed(by: pagenation.disposeBag)
    }
}

class PagenationStateCompleted: PagenationState {
    static let shared = PagenationStateCompleted()
    
    override func loadMoreData<E>(_ pagenation: Pagenation<E>) {
    }
}

class PagenationStateFetchedContents<Element>: PagenationState {
    private (set) var contents: [Element]
    
    init(_ contents: [Element]) {
        self.contents = contents
    }
}

class PagenationStateInitial: PagenationState {
    static let shared = PagenationStateInitial()
}

class PagenationStateError: PagenationState {
    static let shared = PagenationStateError()
}

class PagenationStateLoading: PagenationState {
    override func loadMoreData<E>(_ pagenation: Pagenation<E>) {
    }
    
    override func reloadData<E>(_ pagenation: Pagenation<E>) {
    }
}

class PagenationStateReloading: PagenationStateLoading {
    static let shared = PagenationStateReloading()
}

class PagenationStateLoadingMore: PagenationStateLoading {
    static let shared = PagenationStateLoadingMore()
}

func abscractMethod() -> Swift.Never {
    noImplementation()
}

func noImplementation() -> Swift.Never {
    fatalError()
}

class Pagenation<Element: Equatable>: ObservableConvertibleType {
    typealias E = [Element]
    typealias State = PagenationState
    typealias ElementFactory = (Pagenation<Element>) -> Observable<[Element]>
    
    private (set) var state: BehaviorRelay<State>
    private (set) var elementFactory: ElementFactory?
    private (set) var contents = BehaviorRelay<E>(value: [])
    fileprivate var _observable: Observable<E>
    private (set) var disposeBag = DisposeBag()
    

    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         elementFactory: ElementFactory? = nil)
    {
        state  = BehaviorRelay<State>(value: PagenationStateInitial.shared)
        self.elementFactory = elementFactory
        _observable = state.asObservable().scan(E()) { (collected, state) -> E in
            switch state {
            case is PagenationStateInitial:
                return E()
            case is PagenationStateCompleted:
                return collected
            case let state as PagenationStateFetchedContents<Element>:
                return collected + state.contents
            default:
                return collected
            }
            }.distinctUntilChanged()
        
        reload?.emit(onNext: { [weak self] (_) in
            self?.loadMoreData()
        }).disposed(by: disposeBag)
        
        loadMore?.emit(onNext: { [weak self] (_) in
            self?.reloadData()
        }).disposed(by: disposeBag)
        
        _observable.bind(to: contents).disposed(by: disposeBag)
    }
    
    func createElementsObservable() -> Observable<[Element]> {
        return elementFactory?(self) ?? Observable<[Element]>.empty()
    }
    
    func asObservable() -> Observable<[Element]> {
        return _observable
    }

    func loadMoreData() {
        state.value.loadMoreData(self)
    }
    
    func reloadData() {
        state.value.reloadData(self)
    }
    
    // MARK: - State change hook method
    func stateInitial() {
    }
    
    func stateError() {
    }
    
    func stateReloading() {
    }
    
    func stateLoadingMore() {
    }
    
    func stateFetched(contents: [Element]) {
    }
    
    func stateCompleted() {
    }
}
