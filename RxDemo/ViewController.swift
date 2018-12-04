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

protocol AwtensionCompatible {
    associatedtype CompatibleType
    
    static var aw: Awtension<CompatibleType>.Type { get set }
    
    var aw: Awtension<CompatibleType> { get set }
}

extension AwtensionCompatible {
    static var aw: Awtension<Self>.Type {
        get {
            return Awtension<Self>.self
        }
        set {
        }
    }
    
    var aw: Awtension<Self> {
        get {
            return Awtension(self)
        }
        set {
        }
    }
}

extension NSObject: AwtensionCompatible { }

struct Awtension<Base> {
    var base: Base
    
    init(_ base: Base) {
        self.base = base
    }
}

extension Awtension where Base: UIImage {
    func resize(memorySize: Int) -> Data? {
        var range: (min: CGFloat, max: CGFloat) = (0, 1)
        
        var data: Data!

        repeat {
            let mid = (range.min + range.max) / 2
            data = Awtension.dataOfImage(base, withScale: mid)
            if data.count > memorySize {
                range.max = mid
            } else {
                range.min = mid
            }
        } while (range.max - range.min) > 0.01
        
        return Awtension.dataOfImage(base, withScale: range.min)
    }
    
    private static func resize(image: UIImage, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer {
            UIGraphicsEndImageContext()
        }

        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    private static func dataOfImage(_ image: UIImage, withScale scale: CGFloat) -> Data {
        let size = CGSize(width: floor(image.size.width * scale), height: floor(image.size.height * scale))
        
        guard size != .zero else {
            return Data()
        }
        
        let resizedImage = Awtension.resize(image: image, size: size)
        return UIImagePNGRepresentation(resizedImage) ?? Data()
    }
}
