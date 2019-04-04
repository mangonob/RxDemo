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

fileprivate enum CCPagenatorState<T> {
    case initial
    case completed
    case fetchContents([T])
    case error
}

class CCPagenator<T: Codable> {
    var isLoading: Driver<Bool>
    var contents = BehaviorSubject<[T]>(value: [])
    var provider = CCPagenatorProvider<T>()

    var endRefreshing: Driver<Void>!
    var endLoadMore: Driver<Void>!
    var endNoMoreData: Driver<Void>!
    var resetNoMoreData: Driver<Void>!

    private var disposeBag = DisposeBag()

    init(input: (refreshing: Observable<Void>, loadMore: Observable<Void>)) {
        let activity = RXActivity()
        isLoading = activity.asDriver(onErrorJustReturn: false)
        
        let refreshingState = input.refreshing.share().withLatestFrom(activity).filter { !$0 }
            .flatMapLatest { (_) -> Observable<[T]> in
                return self.observableForRefreshing().trackActivity(by: activity)
            }.map { (value) -> CCPagenatorState<T> in
                return value.isEmpty ? .completed : .fetchContents(value)
            }.flatMap { (state) -> Observable<CCPagenatorState<T>> in
                switch state {
                case .completed, .fetchContents(_):
                    return Observable.of(CCPagenatorState.initial, state)
                default:
                    return Observable.just(state)
                }
            }.catchErrorJustReturn(.error)
        
        let loadMoreState = input.loadMore.share().withLatestFrom(activity).filter { !$0 }
            .flatMapLatest { (_) -> Observable<[T]> in
                return self.observableForLoadMore().trackActivity(by: activity)
            }.map { (value) -> CCPagenatorState<T> in
                return value.isEmpty ? .completed : .fetchContents(value)
            }.catchErrorJustReturn(.error)
        
        let status = Observable<CCPagenatorState<T>>.merge([refreshingState, loadMoreState]).share()
        
        status.scan([T]()) { (contents, state) -> [T] in
            switch state {
            case .initial:
                return []
            case .fetchContents(let values):
                return contents + values
            default:
                return contents
            }
            }.bind(to: contents).disposed(by: disposeBag)
        
        let endRefresh = status.filter { (state) -> Bool in
            switch state {
            case .completed, .fetchContents(_), .error:
                return true
            default:
                return false
            }
            }.map{ _ -> Void in }

        endRefreshing = Observable.merge([
            endRefresh,
            input.refreshing.share().withLatestFrom(activity).filter { $0 }.map { _ -> Void in }
            ]).asDriver(onErrorJustReturn: ())
        
        endLoadMore = Observable.merge([
            endRefresh,
            input.loadMore.share().withLatestFrom(activity).filter { $0 }.map { _ -> Void in }
            ]).asDriver(onErrorJustReturn: ())
    }
    
    func observableForRefreshing() -> Observable<[T]> {
        return provider.observableForRefresh(self)
    }
    
    func observableForLoadMore() -> Observable<[T]> {
        return provider.observableForLoadMore(self)
    }
}

class CCPagenatorProvider<T: Codable> {
    typealias Provider = (CCPagenator<T>) -> Observable<[T]>
    private var refreshingProvider: Provider?
    private var loadMoreProvider: Provider?

    func observableForRefresh(_ pagenator: CCPagenator<T>) -> Observable<[T]> {
        return refreshingProvider?(pagenator) ?? Observable.empty()
    }
    
    func observableForLoadMore(_ pagenator: CCPagenator<T>) -> Observable<[T]> {
        return loadMoreProvider?(pagenator) ?? Observable.empty()
    }
    
    init(refreshing: Provider? = nil, loadMore: Provider? = nil) {
        self.refreshingProvider = refreshing
        self.loadMoreProvider = loadMore
    }
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
        
        let headerRefreshing = tableView.mj_header.rx.refreshing.asObservable()
        let footerRefreshing = tableView.mj_footer.rx.refreshing.asObservable()
        
        pagenator = CCPagenator<Int>(input: (headerRefreshing, footerRefreshing))
        pagenator.endRefreshing.drive(tableView.mj_header.rx.endRefreshing).disposed(by: disposeBag)
        pagenator.endLoadMore.drive(tableView.mj_footer.rx.endRefreshing).disposed(by: disposeBag)
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
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//        cell.detailTextLabel?.text = pagenation.contents[indexPath.row].description
        cell.textLabel?.text = indexPath.row.description
        return cell
    }
}
