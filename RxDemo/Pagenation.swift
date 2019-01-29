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

class PagenationState: NSObject {
    func setState<E: Any>(_ pagenation: Pagenation<E>, state: PagenationState) {
        pagenation.state = state
        
        switch state {
        case is PagenationStateInitial:
            pagenation.contents.removeAll()
        case let state as PagenationStateFetchedContents<E>:
            pagenation.contents.append(contentsOf: state.contents)
        default:
            break
        }
    }
    
    func reloadData<E>(_ pagenation: Pagenation<E>, _ loader: Pagenation<E>.ElementLoader) {
        setState(pagenation, state: PagenationStateReloading.shared)

        loader { (error, elements) in
            if let error = error {
                self.setState(pagenation, state: PagenationStateError(error))
                return
            }
            
            guard let elements = elements else {
                return
            }
            
            self.setState(pagenation, state: PagenationStateInitial.shared)
            self.setState(pagenation, state: PagenationStateFetchedContents(elements))
        }
    }
    
    func loadMoreData<E>(_ pagenation: Pagenation<E>, _ loader: Pagenation<E>.ElementLoader) {
        setState(pagenation, state: PagenationStateLoadingMore.shared)
        
        loader { (error, elements) in
            if let error = error {
                self.setState(pagenation, state: PagenationStateError(error))
                return
            }
            
            guard let elements = elements else {
                return
            }
            
            self.setState(pagenation, state: elements.isEmpty ? PagenationStateCompleted.shared : PagenationStateFetchedContents(elements))
        }
    }
}

class PagenationStateCompleted: PagenationState {
    static let shared = PagenationStateCompleted()

    override func loadMoreData<E>(_ pagenation: Pagenation<E>, _ loader: Pagenation<E>.ElementLoader) {
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
    private (set) var error: Error
    
    init(_ error: Error) {
        self.error = error
    }
}

class PagenationStateLoading: PagenationState {
    override func loadMoreData<E>(_ pagenation: Pagenation<E>, _ loader: Pagenation<E>.ElementLoader) {
    }
    
    override func reloadData<E>(_ pagenation: Pagenation<E>, _ loader: Pagenation<E>.ElementLoader) {
    }
}

class PagenationStateReloading: PagenationStateLoading {
    static let shared = PagenationStateReloading()
}

class PagenationStateLoadingMore: PagenationStateLoading {
    static let shared = PagenationStateLoadingMore()
}

func abscractMethod() -> Swift.Never {
    fatalError("Can't invoke an abscract method.")
}

class Pagenation<Element>: NSObject {
    fileprivate (set) var contents = [Element]()
    @objc dynamic var state: PagenationState = PagenationStateInitial.shared
    typealias CompletionHandler = (Error?, [Element]?) -> Void
    typealias ElementLoader = (@escaping CompletionHandler) -> Void

    func reloadData(_ loader: ElementLoader) {
        state.reloadData(self, loader)
    }
    
    func loadMoreData(_ loader: ElementLoader) {
        state.loadMoreData(self, loader)
    }
}
