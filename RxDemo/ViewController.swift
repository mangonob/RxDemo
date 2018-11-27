//
//  ViewController.swift
//  RxDemo
//
//  Created by 高炼 on 2018/11/22.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    lazy var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        confirmButton.layer.cornerRadius = 5
        
        let loginViewModel = LoginViewModel(
            .init(username: usernameTextField.rx.value.orEmpty.asObservable(),
                  password: passwordTextField.rx.value.orEmpty.asObservable(),
                  loginEvent: confirmButton.rx.tap.asObservable())
        )
        
        loginViewModel.usernameValid.map { $0 ? UserStatus.success : UserStatus.faild }
            .bind(to: usernameTextField.rx.userStatus )
            .disposed(by: disposeBag)
        
        loginViewModel.passwordValid.map { $0 ? UserStatus.success : UserStatus.faild }
            .bind(to: passwordTextField.rx.userStatus )
            .disposed(by: disposeBag)
        
        loginViewModel.loginEnable.map { $0 ? UserStatus.success : UserStatus.faild }
            .bind(to: confirmButton.rx.userStatus)
            .disposed(by: disposeBag)
    }
}

