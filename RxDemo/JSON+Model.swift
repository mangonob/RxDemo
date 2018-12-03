//
//  JSON+Model.swift
//  RxDemo
//
//  Created by 高炼 on 2018/12/3.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
    var moreInfo: String? {
        return self["moreInfo"].string
    }
    
    var data: JSON {
        return self["data"]
    }
    
    func decode<T: Codable>(ofClass cls: T.Type) -> T? {
        guard let data = try? self.rawData() else {
            return nil
        }
        return try? JSONDecoder().decode(cls, from: data)
    }
}
