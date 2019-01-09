//
//  TableViewController.swift
//  RxDemo
//
//  Created by 高炼 on 2019/1/4.
//  Copyright © 2019 BaiYiYuan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import MJRefresh

class CustomElementFactory: PagenationElementsFactory<Int> {
    lazy var mock = Mock.init { () -> [Int] in
        return [1, 2, 3, 4]
    }
    
    override func createObservable(_ context: Pagenation<Int>) -> Observable<[Int]> {
        return mock.rx.request(type: [Int].self)
    }
}

class TableViewController: UITableViewController {
    fileprivate lazy var pagenation = Pagenation(elementsFactory: CustomElementFactory())

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.pagenation.reloadData()
        })
        
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.pagenation.loadMoreData()
        })
        
        pagenation.asObservable().asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (_) in
                self?.tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.automatic)
                self?.tableView.mj_header.endRefreshing()
                self?.tableView.mj_footer.endRefreshing()
            }).disposed(by: pagenation.disposeBag)
        
        pagenation.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pagenation.contents.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = pagenation.contents.value[indexPath.row].description
        return cell
    }
}
