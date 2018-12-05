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
    @IBOutlet weak var loginIndicatory: UIActivityIndicatorView!
    
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
        
        loginViewModel.isLoading.asObservable()
            .bind(to: loginIndicatory.rx.isAnimating )
            .disposed(by: disposeBag)
        
        loginViewModel.isLoading.asObservable()
            .map { $0 ? "登录中" : "登录" }
            .bind(to: confirmButton.rx.title() )
            .disposed(by: disposeBag)
        
        loginViewModel.account.subscribe(onNext: { [weak self] response in
            switch response {
            case .account:
                self?.navigationController?.pushViewController(TestViewController.instance(), animated: true)
            case .moreInfo(let moreInfo):
                let alert = UIAlertController(title: "提示", message: moreInfo ?? "登录失败", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
    }
}
