//
//  RDOrderController.swift
//  RxDemo
//
//  Created by 高炼 on 2018/12/3.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DataSource<T>: NSObject, RxTableViewDataSourceType, UITableViewDataSource {
    typealias Element = [[T]]
    var sections: Element
    
    init(_ sections: Element) {
        self.sections = sections
    }
    
    func tableView(_ tableView: UITableView, observedEvent: Event<DataSource.Element>) {
        Binder(self) { (target, element) in
            target.sections = element
            tableView.reloadData()
        }.on(observedEvent)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellFromClass(RDOrderCell.self, for: indexPath)
        return cell
    }
}

class RDOrderController: UIViewController {
    lazy var disposeBag = DisposeBag()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.registerCellNibFromClass(RDOrderCell.self)
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        let sections: [[Int]] = [
            [12, 4, 123, 41, 234],
            [12, 4, 41, 234],
            [12, 4, 123, 41]
        ]
        
        Observable.just(sections)
            .bind(to: tableView.rx.items(dataSource: DataSource(sections)))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { (indexPath) in
                print(indexPath)
            }).disposed(by: disposeBag)
    }
}

extension RDOrderController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
