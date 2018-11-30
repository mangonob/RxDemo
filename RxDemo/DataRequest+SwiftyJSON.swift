
//
//  DataRequest+.swift
//  Branches
//
//  Created by 高炼 on 2017/12/21.
//  Copyright © 2017年 高炼. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


extension DataRequest {
    @discardableResult
    func responseSwifty(queue: DispatchQueue? = nil,
                        options: JSONSerialization.ReadingOptions = .allowFragments,
                        completion: @escaping (JSON) -> Void)
        -> Self {
            return response(queue: queue, responseSerializer: DataRequest.jsonResponseSerializer()) { (response) in
                guard let value = response.result.value else { return }
                let json = JSON(value)
                #if DEBUG
                    print(json)
                #endif
                completion(json)
            }
    }
    
    @discardableResult
    func error(handler: @escaping (Error) -> Void)
        -> Self {
            return responseJSON { (response) in
                switch response.result {
                case .failure(let error):
                    handler(error)
                default:
                    break
                }
            }
    }
    
    @discardableResult
    func finally(handler: @escaping (DataResponse<Any>) -> Void)
        -> Self {
            return responseJSON(completionHandler: { (response) in
                handler(response)
            })
    }
}
