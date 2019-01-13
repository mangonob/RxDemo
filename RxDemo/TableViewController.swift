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
    private (set) weak var tableView: UITableView!
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         tableView: UITableView,
         elementFactory: @escaping ElementFactory)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: AnonymousElementFactory(elementFactory))
        self.tableView = tableView
        subscribeState()
    }
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         tableView: UITableView,
         elementFactory: PagenationElementFactory<Element>)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: elementFactory)
        self.tableView = tableView
        subscribeState()
    }
    
    private func subscribeState() {
        let reloading = state.map { $0 is PagenationStateReloading }.distinctUntilChanged()
        
        reloading.filter { !$0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.mj_header.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        let loadingMore = state.map { $0 is PagenationStateLoadingMore }.distinctUntilChanged()
            
        loadingMore.filter { !$0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.mj_footer.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        tableView.mj_header.rx.refreshing.withLatestFrom(loadingMore)
            .filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.mj_header.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        tableView.mj_footer.rx.refreshing.withLatestFrom(reloading)
            .filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.mj_footer.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        state.filter { $0 is PagenationStateCompleted }
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.mj_footer.endRefreshingWithNoMoreData()
            })
            .disposed(by: disposeBag)
        
        state.filter { $0 is PagenationStateInitial }
            .subscribe(onNext: { (state) in
                self.tableView.mj_footer.resetNoMoreData()
            })
            .disposed(by: disposeBag)
    }
}

class CollectionViewPagenation<Element: Equatable>: Pagenation<Element> {
    private (set) weak var collectionView: UICollectionView!

    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         collectionView: UICollectionView,
         elementFactory: @escaping ElementFactory)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: AnonymousElementFactory(elementFactory))
        self.collectionView = collectionView
        subscribeState()
    }
    
    init(reload: Signal<Void>? = nil,
         loadMore: Signal<Void>? = nil,
         collectionView: UICollectionView,
         elementFactory: PagenationElementFactory<Element>)
    {
        super.init(reload: reload, loadMore: loadMore, elementFactory: elementFactory)
        self.collectionView = collectionView
        subscribeState()
    }
    
    private func subscribeState() {
        let reloading = state.map { $0 is PagenationStateReloading }.distinctUntilChanged()
        
        reloading.filter { !$0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.mj_header.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        let loadingMore = state.map { $0 is PagenationStateLoadingMore }.distinctUntilChanged()
        
        loadingMore.filter { !$0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.mj_footer.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        collectionView.mj_header.rx.refreshing.withLatestFrom(loadingMore)
            .filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.mj_header.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        collectionView.mj_footer.rx.refreshing.withLatestFrom(reloading)
            .filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.mj_footer.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        state.filter { $0 is PagenationStateCompleted }
            .subscribe(onNext: { [weak self] (_) in
                self?.collectionView.mj_footer.endRefreshingWithNoMoreData()
            })
            .disposed(by: disposeBag)
        
        state.filter { $0 is PagenationStateInitial }
            .subscribe(onNext: { (state) in
                self.collectionView.mj_footer.resetNoMoreData()
            })
            .disposed(by: disposeBag)
    }
}

class TableViewController: UITableViewController {
    fileprivate var pagenation: TableViewPagenation<Int>!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = nil
        
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
            .drive(tableView.rx.items(cellIdentifier: "Cell"), curriedArgument: { row, value, cell in
                cell.textLabel?.text = row.description
                cell.detailTextLabel?.text = value.description
            }).disposed(by: pagenation.disposeBag)
        
        pagenation.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
}
