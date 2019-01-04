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

class PagenationMediator<Element: AnyObject>: ObservableConvertibleType {
    typealias E = [Element]
    private var contents: Variable<[Element]>
    fileprivate var state: PagenationState

    private init() {
        contents = Variable([Element]())
        state = PagenationStateInitial.shared
    }

    convenience init(reload: Signal<Void>, loadMore: Signal<Void>, elements: (PagenationMediator<Element>) -> Observable<Element>) {
        self.init()
    }
    
    func asObservable() -> Observable<[Element]> {
        return contents.asObservable()
    }
}
