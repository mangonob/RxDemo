//
//  Pagenation+Rx.swift
//  RxDemo
//
//  Created by 高炼 on 2019/3/7.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: PagenationProtocol {
    func loadMoreData(loader: @escaping Base.ElementLoader) -> Binder<Void> {
        return Binder<Void>.init(base, binding: { (target, _) in
            target.loadMoreData(loader)
        })
    }
    
    func reloadData(loader: @escaping Base.ElementLoader) -> Binder<Void> {
        return Binder<Void>.init(base, binding: { (target, _) in
            target.reloadData(loader)
        })
    }
}
