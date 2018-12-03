//
//  TestViewController.swift
//  RxDemo
//
//  Created by 高炼 on 2018/12/3.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

@objc protocol TestViewDelegate {
    @objc optional func testViewDidSelect()
}

class TestViewDelegateProxy: DelegateProxy<TestViewController, TestViewDelegate>,
DelegateProxyType {
    public weak private(set) var testViewController: TestViewController?
    
    init(testViewController: TestViewController) {
        self.testViewController = testViewController
        super.init(parentObject: testViewController, delegateProxy: TestViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register { TestViewDelegateProxy(testViewController: $0) }
    }
}

class TestViewController: UIViewController {
    weak var delegate: TestViewDelegate?

    private lazy var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        rx.isSelected.subscribe(onNext: {
            print("\(self): is selected.")
        }).disposed(by: disposeBag)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func selectAction(_ sender: Any) {
        delegate?.testViewDidSelect?()
    }
}

extension TestViewController: HasDelegate {
    typealias Delegate = TestViewDelegate
}

extension Reactive where Base: TestViewController {
    var delegate: DelegateProxy<TestViewController, TestViewDelegate> {
        return TestViewDelegateProxy(testViewController: base)
    }
    
    var isSelected: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(TestViewDelegate.testViewDidSelect))
            .map { (_) -> Void in }
        return ControlEvent.init(events: source)
    }
}
