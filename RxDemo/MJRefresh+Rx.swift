//
//  MJRefresh+Rx.swift
//  RxDemo
//
//  Created by 高炼 on 2019/1/11.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import Foundation
import MJRefresh
import RxSwift
import RxCocoa

extension Reactive where Base: MJRefreshComponent {
    var refreshing: ControlEvent<Void> {
        return ControlEvent(events: base.rx.methodInvoked(#selector(base.beginRefreshing as () -> Void)).map { _ -> Void in })
    }
    
    var endRefreshing: Binder<Void> {
        return Binder.init(base, binding: { (target, _) in
            target.endRefreshing()
        })
    }
}

extension Reactive where Base: MJRefreshFooter {
    var endWithNoMoreData: Binder<Void> {
        return Binder.init(base, binding: { (target, _) in
            target.endRefreshingWithNoMoreData()
        })
    }
    
    var resetNoMoreData: Binder<Void> {
        return Binder.init(base, binding: { (target, _) in
            target.resetNoMoreData()
        })
    }
}
