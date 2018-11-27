//
//  UIControl+UserStatus.swift
//  RxDemo
//
//  Created by 高炼 on 2018/11/27.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ChameleonFramework

enum UserStatus {
    case success
    case faild
    case normal
}

extension Reactive where Base: UITextField {
    var userStatus: Binder<UserStatus> {
        return Binder(base, binding: { (target, result) in
            switch result {
            case .success:
                target.textColor = UIColor.flatGreen
            case .faild:
                target.textColor = UIColor.flatRed
            case .normal:
                target.textColor = UIColor.flatBlack
            }
        })
    }
}

extension Reactive where Base: UIButton {
    var userStatus: Binder<UserStatus> {
        return Binder(base, binding: { (target, result) in
            switch result {
            case .success:
                target.isEnabled = true
                target.backgroundColor = UIColor.flatGreen
            case .faild:
                target.isEnabled = false
                target.backgroundColor = UIColor.flatRed
            case .normal:
                target.isEnabled = true
                target.backgroundColor = UIColor.flatGray
            }
        })
    }
}
