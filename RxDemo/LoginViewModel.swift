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
import SwiftyJSON

class LoginViewModel {
    struct Input {
        var username: Observable<String>
        var password: Observable<String>
        var loginEvent: Observable<Void>
    }
    
    var loginEnable: Observable<Bool>
    var usernameValid: Observable<Bool>
    var passwordValid: Observable<Bool>
    var account: Observable<RDAccount>
    
    init(_ input: Input) {
        usernameValid = input.username.map { 5...20 ~= $0.count }
        passwordValid = input.password.map { 6...18 ~= $0.count }

        let isLoading = RXActivity()

        loginEnable = Observable.combineLatest(
            usernameValid,
            passwordValid,
            isLoading.asObservable()
            ).map {
                $0.0 && $0.1 && !$0.2
        }
        
        let form = Observable.combineLatest(input.username, input.password) { (username: $0, password: $1) }
        
        account = input.loginEvent.withLatestFrom(form)
            .flatMapLatest {
                RDAccount.account(withUsername: $0.username, andPassword: $0.password)
            }
            .trackActivity(by: isLoading)
    }
}
