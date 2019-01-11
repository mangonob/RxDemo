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

class TableViewPagenation<Element: Equatable>: Pagenation<Element> {
    private (set) weak var tableView: UITableView?
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         tableView: UITableView,
         elementFactory: @escaping ElementFactory)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: AnonymousElementFactory(elementFactory))
        self.tableView = tableView
    }
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         tableView: UITableView,
         elementFactory: PagenationElementFactory<Element>)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: elementFactory)
        self.tableView = tableView
    }

    override func exitCompleted() {
        tableView?.mj_footer.resetNoMoreData()
    }

    override func exitReloading() {
        tableView?.mj_header.endRefreshing()
    }

    override func exitLoadingMore() {
        tableView?.mj_footer.endRefreshing()
    }
    
    override func enterCompleted() {
        tableView?.mj_footer.endRefreshingWithNoMoreData()
    }
}

class CollectionViewPagenation<Element: Equatable>: Pagenation<Element> {
    private (set) weak var collectionView: UICollectionView?

    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         collectionView: UICollectionView,
         elementFactory: @escaping ElementFactory)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: AnonymousElementFactory(elementFactory))
        self.collectionView = collectionView
    }
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         collectionView: UICollectionView,
         elementFactory: PagenationElementFactory<Element>)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: elementFactory)
        self.collectionView = collectionView
    }
    
    override func exitCompleted() {
        collectionView?.mj_footer.resetNoMoreData()
    }
    
    override func exitReloading() {
        collectionView?.mj_header.endRefreshing()
    }
    
    override func exitLoadingMore() {
        collectionView?.mj_footer.endRefreshing()
    }
    
    override func enterCompleted() {
        collectionView?.mj_footer.endRefreshingWithNoMoreData()
    }
}

class TableViewController: UITableViewController {
    fileprivate var pagenation: TableViewPagenation<Int>!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.mj_header = MJRefreshNormalHeader()
        tableView.mj_footer = MJRefreshAutoNormalFooter()
        
        pagenation = TableViewPagenation<Int>
            .init(reload: tableView.mj_header.rx.refreshing.asSignal(),
                  loadMore: tableView.mj_footer.rx.refreshing.asSignal(),
                  tableView: tableView,
                  elementFactory: { (pagenation: Pagenation<Int>) -> Observable<[Int]> in
                    let shouldCompleted = pagenation.state.value is PagenationStateLoadingMore && pagenation.contents.value.count >= 10
                    
                    let mock = Mock.init { () -> [Int] in
                        let total = arc4random() % 5 + 5
                        return shouldCompleted ? [Int]() : [Int].init(repeating: 0, count: Int(total)).map { _ in Int(arc4random() % 10 + 1) }
                    }
                    
                    return mock.rx.request(type: [Int].self)
            })
        
        pagenation.asObservable().asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (_) in
                self?.tableView.reloadSections(IndexSet(integer: 0), with: UITableViewRowAnimation.automatic)
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
