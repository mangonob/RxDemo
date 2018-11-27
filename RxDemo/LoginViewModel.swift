//
//  LoginViewModel.swift
//  RxDemo
//
//  Created by 高炼 on 2018/11/27.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire

class LoginViewModel {
    struct Input {
        var username: Observable<String>
        var password: Observable<String>
        var loginEvent: Observable<Void>
    }
    
    var loginEnable: Observable<Bool>
    var usernameValid: Observable<Bool>
    var passwordValid: Observable<Bool>

    init(_ input: Input) {
        usernameValid = input.username.map { 5...20 ~= $0.count }
        passwordValid = input.password.map { 6...18 ~= $0.count }
        
        loginEnable = Observable.combineLatest(
            usernameValid,
            passwordValid
            ).map { $0.0 && $0.1 }
    }
}
