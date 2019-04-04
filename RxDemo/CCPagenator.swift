//
//  CCPagenator.swift
//  RxDemo
//
//  Created by 高炼 on 2019/4/4.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

fileprivate enum CCPagenatorState<T> {
    case initial
    case completed
    case fetchContents([T])
    case error
}

class CCPagenator<T: Codable> {
    var isLoading: Driver<Bool>
    var contents = BehaviorRelay<[T]>(value: [])
    var provider = CCPagenatorProvider<T>()
    
    var endRefreshing: Signal<Void>!
    var endLoadMore: Signal<Void>!
    var endNoMoreData: Signal<Void>!
    var resetNoMoreData: Signal<Void>!
    
    private var disposeBag = DisposeBag()
    
    init(input: (refreshing: Signal<Void>, loadMore: Signal<Void>)) {
        let activity = RXActivity()
        isLoading = activity.asDriver(onErrorJustReturn: false)
        
        let refreshingState = input.refreshing.withLatestFrom(isLoading).filter { !$0 }
            .flatMapLatest({ (_) -> Driver<CCPagenatorState<T>> in
                return self.observableForRefreshing().trackActivity(by: activity)
                    .map({ (value) -> CCPagenatorState<T> in
                        return value.isEmpty ? .completed : .fetchContents(value)
                    }).flatMap({ (state) -> Observable<CCPagenatorState<T>> in
                        switch state {
                        case .completed, .fetchContents(_):
                            return Observable.of(.initial, state)
                        default:
                            return Observable.just(state)
                        }
                    }).asDriver(onErrorJustReturn: .error)
            })
        
        let loadMoreState = input.loadMore.withLatestFrom(isLoading).filter { !$0 }
            .flatMapLatest { (_) -> Driver<CCPagenatorState<T>> in
                return self.observableForLoadMore().trackActivity(by: activity)
                    .map({ (value) -> CCPagenatorState<T> in
                        return value.isEmpty ? .completed : .fetchContents(value)
                    }).asDriver(onErrorJustReturn: .error)
        }
        
        let status = Driver<CCPagenatorState<T>>.merge([refreshingState, loadMoreState])
        
        status.scan([T]()) { (contents, state) -> [T] in
            switch state {
            case .initial:
                return []
            case .fetchContents(let values):
                return contents + values
            default:
                return contents
            }
            }.drive(contents).disposed(by: disposeBag)
        
        endRefreshing = isLoading.filter { !$0 }.map { _ -> Void in }.asSignal(onErrorJustReturn: ())
        endLoadMore = isLoading.filter { !$0 }.map { _ -> Void in }.asSignal(onErrorJustReturn: ())
    }

    func observableForRefreshing() -> Observable<[T]> {
        return provider.observableForRefresh(self)
    }
    
    func observableForLoadMore() -> Observable<[T]> {
        return provider.observableForLoadMore(self)
    }
}

class CCPagenatorProvider<T: Codable> {
    typealias Provider = (CCPagenator<T>) -> Observable<[T]>
    private var refreshingProvider: Provider?
    private var loadMoreProvider: Provider?
    
    func observableForRefresh(_ pagenator: CCPagenator<T>) -> Observable<[T]> {
        return refreshingProvider?(pagenator) ?? Observable.empty()
    }
    
    func observableForLoadMore(_ pagenator: CCPagenator<T>) -> Observable<[T]> {
        return loadMoreProvider?(pagenator) ?? Observable.empty()
    }
    
    init(refreshing: Provider? = nil, loadMore: Provider? = nil) {
        self.refreshingProvider = refreshing
        self.loadMoreProvider = loadMore
    }
}

class HWFlashSaleProvider: CCPagenatorProvider<Double> {
    override func observableForRefresh(_ pagenator: CCPagenator<Double>) -> Observable<[Double]> {
        return .empty()
    }
    
    override func observableForLoadMore(_ pagenator: CCPagenator<Double>) -> Observable<[Double]> {
        return .empty()
    }
}

