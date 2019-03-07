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

class ScrollViewPagenation<Element>: Pagenation<Element> {
    internal (set) weak var scrollView: UIScrollView!
    
    override var state: PagenationState {
        didSet {
            switch state {
            case is PagenationStateError:
                refreshHeader().endRefreshing()
                refreshFooter().endRefreshing()
            case is PagenationStateFetchedContents<Element>:
                refreshHeader().endRefreshing()
                refreshFooter().endRefreshing()
            case is PagenationStateCompleted:
                refreshHeader().endRefreshing()
                refreshFooter().endRefreshingWithNoMoreData()
            default: break
            }
        }
    }
    
    func refreshHeader() -> MJRefreshHeader {
        return scrollView.mj_header
    }
    
    func refreshFooter() -> MJRefreshFooter {
        return scrollView.mj_footer
    }
    
    override func reloadData(_ loader: (@escaping (Error?, [Element]?) -> Void) -> Void) {
        if state is PagenationStateLoading {
            scrollView.mj_header.endRefreshing()
        }
        
        super.reloadData(loader)
    }
    
    override func loadMoreData(_ loader: (@escaping (Error?, [Element]?) -> Void) -> Void) {
        if state is PagenationStateLoading {
            scrollView.mj_footer.endRefreshing()
        }
        
        super.loadMoreData(loader)
    }

    init(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
    }
}

class TableViewPagenation<Element>: ScrollViewPagenation<Element> {
    override var state: PagenationState {
        didSet {
            switch state {
            case is PagenationStateFetchedContents<Element>:
                tableView.reloadData()
            case is PagenationStateCompleted:
                tableView.reloadData()
            default: break
            }
        }
    }
    
    var tableView: UITableView! {
        set {
            scrollView = newValue
        }
        get {
            return (scrollView as! UITableView)
        }
    }
    
    init(_ tableView: UITableView) {
        super.init(tableView)
    }
}

class CollectionViewPagenation<Element>: ScrollViewPagenation<Element> {
    override var state: PagenationState {
        didSet {
            switch state {
            case is PagenationStateFetchedContents<Element>:
                collectionView.reloadData()
            case is PagenationStateCompleted:
                collectionView.reloadData()
            default: break
            }
        }
    }
    
    var collectionView: UICollectionView! {
        set {
            scrollView = newValue
        }
        get {
            return (scrollView as! UICollectionView)
        }
    }
    
    init(_ collectionView: UICollectionView) {
        super.init(collectionView)
    }
}

class TableViewController: UITableViewController {
    @IBOutlet weak var errorLabel: UITextField!
    @IBOutlet weak var contentsLabel: UITextField!
    
    fileprivate lazy var pagenation = TableViewPagenation<Int>.init(self.tableView)
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: nil, refreshingAction: nil)
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingTarget: nil, refreshingAction: nil)

        tableView.mj_header.rx.refreshing.bind(to: pagenation.rx.reloadData(loader: { [weak self] (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: {
                if let errorDescription = self?.errorLabel.text,
                    !errorDescription.isEmpty {
                    completion(RuntimeError.loadError(errorDescription), nil)
                    return
                }
                
                let contentsDescription = self?.contentsLabel.text
                let contents = contentsDescription?.split(separator: ".").compactMap { Int($0) } ?? []
                completion(nil, contents)
            })
        })).disposed(by: disposeBag)
        
        tableView.mj_footer.rx.refreshing.bind(to: pagenation.rx.loadMoreData(loader: { [weak self] (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: {
                if let errorDescription = self?.errorLabel.text,
                    !errorDescription.isEmpty {
                    completion(RuntimeError.loadError(errorDescription), nil)
                    return
                }
                
                let contentsDescription = self?.contentsLabel.text
                let contents = contentsDescription?.split(separator: ".").compactMap { Int($0) } ?? []
                completion(nil, contents)
            })
        })).disposed(by: disposeBag)
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
        return pagenation.contents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.detailTextLabel?.text = pagenation.contents[indexPath.row].description
        cell.textLabel?.text = indexPath.row.description
        return cell
    }
}
