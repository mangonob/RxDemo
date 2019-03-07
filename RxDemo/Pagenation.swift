//
//  Pagenation.swift
//  RxDemo
//
//  Created by 高炼 on 2019/1/4.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import Foundation

class PagenationState: NSObject {
    func setState<E: Any>(_ pagenation: Pagenation<E>, state: PagenationState) {
        switch state {
        case is PagenationStateInitial:
            pagenation.contents.removeAll()
        case let state as PagenationStateFetchedContents<E>:
            pagenation.contents.append(contentsOf: state.contents)
        default:
            break
        }
        
        pagenation.state = state
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
            self.setState(pagenation, state: elements.isEmpty ? PagenationStateCompleted.shared : PagenationStateFetchedContents(elements))
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

protocol PagenationProtocol: AnyObject {
    associatedtype Element
    
    typealias CompletionHandler = (Error?, [Element]?) -> Void
    typealias ElementLoader = (@escaping CompletionHandler) -> Void
    
    func reloadData(_ loader: ElementLoader)
    
    func loadMoreData(_ loader: ElementLoader)
}

class Pagenation<Element>: NSObject, PagenationProtocol {
    var size: Int = 10
    
    var page: Int {
        return contents.count % size
    }
    
    var offset: Int {
        return contents.count
    }

    fileprivate (set) var contents = [Element]()
    var state: PagenationState = PagenationStateInitial.shared

    func reloadData(_ loader: (@escaping (Error?, [Element]?) -> Void) -> Void) {
        state.reloadData(self, loader)
    }
    
    func loadMoreData(_ loader: (@escaping (Error?, [Element]?) -> Void) -> Void) {
        state.loadMoreData(self, loader)
    }
}
