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
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(1000), execute: {
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
    func setState<E: Any>(_ pagenation: Pagenation<E>?, state: PagenationState) {
        pagenation?.state.value = state
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

extension PagenationState {
    var isReloading: Bool {
        return self is PagenationStateReloading
    }
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

class PagenationElementsFactory<Element: Equatable> {
    func createObservable(_ context: Pagenation<Element>) -> Observable<[Element]> {
        abscractMethod()
    }
}

class Pagenation<Element: Equatable>: ObservableConvertibleType {
    typealias E = [Element]
    typealias State = PagenationState
    private (set) var state = Variable<State>(PagenationStateInitial.shared)
    private (set) var contents = Variable<E>([])
    fileprivate var elementsFactory: PagenationElementsFactory<Element>
    fileprivate var _observable: Observable<E>
    private (set) var disposeBag = DisposeBag()

    init(reload: Signal<Void>? = nil, loadMore: Signal<Void>? = nil, elementsFactory: PagenationElementsFactory<Element>) {
        self.elementsFactory = elementsFactory

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
        return elementsFactory.createObservable(self)
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
}
