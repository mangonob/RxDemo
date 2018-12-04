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

@objc protocol TestViewDataSource {
    @objc optional func testViewControllerTitleForButton() -> String
}

class TestViewDelegateProxy: DelegateProxy<TestViewController, TestViewDelegate>,
DelegateProxyType, TestViewDelegate {
    weak private(set) var testViewController: TestViewController?
    
    init(testViewController: TestViewController) {
        self.testViewController = testViewController
        super.init(parentObject: testViewController, delegateProxy: TestViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register { TestViewDelegateProxy(testViewController: $0) }
    }
}

class TestViewDataSourceProxy: DelegateProxy<TestViewController, TestViewDataSource>,
DelegateProxyType, TestViewDataSource {
    weak private(set) var testViewController: TestViewController?
    
    class EmptyTestViewDataSource: TestViewDataSource {
        static let shared = EmptyTestViewDataSource()
        private init() { }
        
        func testViewControllerTitleForButton() -> String {
            return "Please implement yours dataSource."
        }
    }
    
    init(testViewController: TestViewController) {
        self.testViewController = testViewController
        super.init(parentObject: testViewController, delegateProxy: TestViewDataSourceProxy.self)
    }
    
    private weak var forwardDelegate: TestViewDataSource?

    static func registerKnownImplementations() {
        register { TestViewDataSourceProxy(testViewController: $0) }
    }
    
    func testViewControllerTitleForButton() -> String {
        return (forwardDelegate ?? EmptyTestViewDataSource.shared).testViewControllerTitleForButton?() ?? ""
    }
    
    override func setForwardToDelegate(_ delegate: TestViewDataSource?, retainDelegate: Bool) {
        forwardDelegate = delegate
        super.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    }
}

class TitleDataSource: TestViewDataSource {
    deinit {
        print("\(self) deinit.")
    }
    
    func testViewControllerTitleForButton() -> String {
        return "Simple Title"
    }
}

class TestViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    
    weak var delegate: TestViewDelegate?
    weak var dataSource: TestViewDataSource?

    private lazy var disposeBag = DisposeBag()
    
    let titleDataSource = TitleDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        rx.isSelected.subscribe(onNext: { [weak self] in
            let alert = UIAlertController(title: "提示", message: "\(self?.description ?? "") has been selected.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }).disposed(by: disposeBag)

        rx.setDataSource(titleDataSource)
            .disposed(by: disposeBag)
        
        reloadData()
    }
    
    func reloadData() {
        button.setTitle(dataSource?.testViewControllerTitleForButton?(), for: .normal)
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

extension TestViewController: HasDataSource {
    typealias DataSource = TestViewDataSource
}

extension Reactive where Base: TestViewController {
    var delegate: DelegateProxy<TestViewController, TestViewDelegate> {
        return TestViewDelegateProxy.proxy(for: base)
    }
    
    var dataSource: DelegateProxy<TestViewController, TestViewDataSource> {
        return TestViewDataSourceProxy.proxy(for: base)
    }

    var isSelected: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(TestViewDelegate.testViewDidSelect))
            .map { (_) -> Void in }
        return ControlEvent.init(events: source)
    }
    
    func setDataSource(_ dataSource: TestViewDataSource)
        -> Disposable {
            return TestViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: base)
    }
}
