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

enum RuntimeError: Error {
    case loadError(String?)
}

class TableViewController: UITableViewController {
    @IBOutlet weak var errorLabel: UITextField!
    @IBOutlet weak var contentsLabel: UITextField!
    
    var pagenator: CCPagenator<Int>!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: nil, refreshingAction: nil)
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingTarget: nil, refreshingAction: nil)
        
        let headerRefreshing = tableView.mj_header.rx.refreshing.asSignal()
        let footerRefreshing = tableView.mj_footer.rx.refreshing.asSignal()

        pagenator = CCPagenator<Int>(input: (headerRefreshing, footerRefreshing))
        pagenator.endRefreshing.emit(to: tableView.mj_header.rx.endRefreshing).disposed(by: disposeBag)
        pagenator.endLoadMore.emit(to: tableView.mj_footer.rx.endRefreshing).disposed(by: disposeBag)
        pagenator.provider = CCPagenatorProvider<Int>.init(refreshing: { (_) -> Observable<[Int]> in
            return Observable<[Int]>.create({ (observer) -> Disposable in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: {
                    observer.onNext([1])
                    observer.onCompleted()
                })
                
                return Disposables.create()
            })
        }, loadMore: { (_) -> Observable<[Int]> in
            return Observable<[Int]>.create({ (observer) -> Disposable in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: {
                    observer.onNext([1])
                    observer.onCompleted()
                })
                
                return Disposables.create()
            })
        })
        
        pagenator.contents.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pagenator.contents.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.detailTextLabel?.text = pagenator.contents.value[indexPath.row].description
        cell.textLabel?.text = indexPath.row.description
        return cell
    }
}
