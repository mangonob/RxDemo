//
//  UIViewController+Instance.swift
//  B2B-Seller
//
//  Created by 高炼 on 16/12/27.
//  Copyright © 2016年 高炼. All rights reserved.
//

import UIKit


extension UIViewController {
    class func instance() -> Self {
        return genericGateway(self)
    }
    
    private class func genericGateway<T: UIViewController>(_ type: T.Type) -> T {
        let className = String.init(describing: self)
        
        if Bundle.main.path(forResource: className, ofType: "nib") != nil {
            return T(nibName: className, bundle: nil)
        } else if Bundle.main.path(forResource: className, ofType: "storyboardc") != nil {
            return UIStoryboard(name: className, bundle: nil).instantiateInitialViewController() as! T
        } else {
            return T()
        }
    }
}
