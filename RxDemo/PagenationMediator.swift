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

class PagenationState {
    func setState(_ pagenation: Pagenation<Any>, state: PagenationState) {
        pagenation.state = state
    }
    
    func reloadData(_ pagenation: Pagenation<Any>) {
    }
    
    func loadMoreData(_ pagenation: Pagenation<Any>) {
    }
}

class PagenationStateCompleted: PagenationState {
    static let shared = PagenationStateCompleted()
}

class PagenationStateNeedMoreData: PagenationState {
    static let shared = PagenationStateNeedMoreData()
}

class PagenationStateInitial: PagenationState {
    static let shared = PagenationStateInitial()
    
    override func loadMoreData(_ pagenation: Pagenation<Any>) {
    }
}

func abscractMethod() -> Swift.Never {
    noImplementation()
}

func noImplementation() -> Swift.Never {
    fatalError("")
}

class PagenationElementsFactory<Element> {
    func createObservable(_ context: Pagenation<Element>) -> Observable<[Element]> {
        abscractMethod()
    }
}

protocol PagenationProtocol: AnyObject {
    associatedtype Element
    func loadMoreData()
    func reloadData()
}

class Pagenation<Element: Any>: PagenationProtocol, ObservableConvertibleType, ReactiveCompatible {
    typealias E = [Element]
    public private(set) var contents: Variable<[Element]>
    fileprivate var state: PagenationState
    fileprivate var elementsFactory: PagenationElementsFactory<Element>
    
    init(reload: Signal<Void>, loadMore: Signal<Void>, elementsFactory: PagenationElementsFactory<Element>) {
        contents = Variable([Element]())
        state = PagenationStateInitial.shared
        self.elementsFactory = elementsFactory
    }
    
    func createElementsObservable() -> Observable<[Element]> {
        return elementsFactory.createObservable(self)
    }
    
    func asObservable() -> Observable<[Element]> {
        return contents.asObservable()
    }
    
    func loadMoreData() {
    }
    
    func reloadData() {
    }
}
