//
//  PagenationMediator.swift
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
    func setState(_ pagenation: PagenationMediator<AnyObject>, state: PagenationState) {
        pagenation.state = state
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
}

func abscractMethod() -> Swift.Never {
    noImplementation()
}

func noImplementation() -> Swift.Never {
    fatalError("")
}

class ObservableFactory<Element: Any, Context: Any> {
    func createObservable() -> Observable<Element> {
        abscractMethod()
    }
    
    func createObservable(_ context: Context) -> Observable<Element> {
        abscractMethod()
    }
}

class PagenationElementsFactory<Element: Any>: ObservableFactory<[Element], PagenationMediator<Element>> {
    override func createObservable(_ context: PagenationMediator<Element>) -> Observable<[Element]> {
        abscractMethod()
    }
}

class PagenationMediator<Element: Any>: ObservableConvertibleType {
    typealias E = [Element]
    private var contents: Variable<[Element]>
    fileprivate var state: PagenationState

    private init() {
        contents = Variable([Element]())
        state = PagenationStateInitial.shared
    }

    convenience init(reload: Signal<Void>, loadMore: Signal<Void>, elementsFactory: PagenationElementsFactory<Element>) {
        self.init()
    }
    
    func asObservable() -> Observable<[Element]> {
        return contents.asObservable()
    }
}
