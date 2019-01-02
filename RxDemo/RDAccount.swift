//
//  RDAccount.swift
//  RxDemo
//
//  Created by 高炼 on 2018/11/30.
//  Copyright © 2018 BaiYiYuan. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let rDAccount = try? newJSONDecoder().decode(RDAccount.self, from: jsonData)

import Foundation
import RxAlamofire
import Alamofire
import RxSwift
import RxCocoa
import SwiftyJSON

class RDAccount: Codable {
    var id: String?
    var cpID: Int?
    var phone: String?
    var name: String?
    var avatar: String?
    var shopURL: String?
    var hasPwd: Bool?
    var idCardNum: String?
    var shopID: String?
    var type: String?
    var teamNum: Int?
    var amount: Int?
    var createdAt: Int?
    var createdAtStr: String?
    var hasProfile: Bool?
    var customerNumber: String?
    var hasIdentity: Bool?
    var isLighten: Bool?
    var hasBankInfo: Bool?
    var isShopOwner: Bool?
    var bankUserName: String?
    var bankTincode: String?
    var bankCardNumber: String?
    var bankName: String?
    var isMember: Bool?
    var isProxy: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case cpID = "cpId"
        case phone = "phone"
        case name = "name"
        case avatar = "avatar"
        case shopURL = "shopUrl"
        case hasPwd = "hasPwd"
        case idCardNum = "idCardNum"
        case shopID = "shopId"
        case type = "type"
        case teamNum = "teamNum"
        case amount = "amount"
        case createdAt = "createdAt"
        case createdAtStr = "createdAtStr"
        case hasProfile = "hasProfile"
        case customerNumber = "customerNumber"
        case hasIdentity = "hasIdentity"
        case isLighten = "isLighten"
        case hasBankInfo = "hasBankInfo"
        case isShopOwner = "isShopOwner"
        case bankUserName = "bankUserName"
        case bankTincode = "bankTincode"
        case bankCardNumber = "bankCardNumber"
        case bankName = "bankName"
        case isMember = "isMember"
        case isProxy = "isProxy"
    }
    
    enum Response {
        case account(RDAccount)
        case moreInfo(String?)
    }
    
    static func account(withUsername username: String, andPassword password: String) -> Observable<Response> {
        var params = [String: Any]()
        params["authType"] = "MOBILE_PHONE"
        params["u"] = username
        params["mobilePhoneVerifyCode"] = password
        
        return Alamofire.request("https://uathwapi.handeson.com/v2/signin_check", method: .post, parameters: params).rx
            .responseData()
            .map { JSON($0.1) }
            .map({ (json) -> Response in
                if let account = json.data.decode(ofClass: RDAccount.self) {
                    return Response.account(account)
                } else {
                    return Response.moreInfo(json.moreInfo)
                }
            }).catchErrorJustReturn(.moreInfo(nil))
    }
}
