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

class TableViewPagenation<Element: Equatable>: Pagenation<Element> {
    private (set) weak var tableView: UITableView!
    
    init(_ tableView: UITableView) {
        self.tableView = tableView
    }
}

class CollectionViewPagenation<Element: Equatable>: Pagenation<Element> {
    private (set) weak var collectionView: UICollectionView!
    
    init(_ collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
}

class TableViewController: UITableViewController {
    @IBOutlet weak var errorLabel: UITextField!
    @IBOutlet weak var contentsLabel: UITextField!
    
    fileprivate lazy var pagenation = TableViewPagenation<Int>.init(self.tableView)

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard !(self?.pagenation.state is PagenationStateLoading) else {
                self?.tableView.mj_header.endRefreshing()
                return
            }
            
            self?.pagenation.reloadData({ (completion) in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: {
                    self?.tableView.mj_header.endRefreshing()
                    
                    if let errorDescription = self?.errorLabel.text,
                        !errorDescription.isEmpty {
                        completion(RuntimeError.loadError(errorDescription), nil)
                        return
                    }

                    let contentsDescription = self?.contentsLabel.text
                    let contents = contentsDescription?.split(separator: ".").compactMap { Int($0) } ?? []
                    completion(nil, contents)
                    self?.tableView.reloadData()
                })
            })
        })
        
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard !(self?.pagenation.state is PagenationStateLoading ||
                self?.pagenation.state is PagenationStateCompleted) else {
                self?.tableView.mj_footer.endRefreshing()
                return
            }
            
            self?.pagenation.loadMoreData({ (completion) in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: {
                    self?.tableView.mj_footer.endRefreshing()
                    
                    if let errorDescription = self?.errorLabel.text,
                        !errorDescription.isEmpty {
                        completion(RuntimeError.loadError(errorDescription), nil)
                        return
                    }
                    
                    let contentsDescription = self?.contentsLabel.text
                    let contents = contentsDescription?.split(separator: ".").compactMap { Int($0) } ?? []
                    completion(nil, contents)
                    self?.tableView.reloadData()
                })
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
        return pagenation.contents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.detailTextLabel?.text = pagenation.contents[indexPath.row].description
        cell.textLabel?.text = indexPath.row.description
        return cell
    }
}
