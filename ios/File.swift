//
//  File.swift
//  mkmk
//
//  Created by Admin on 31/12/2021.
//

import UIKit
import Foundation

class File:UIViewController {
  override func viewDidLoad() {
      super.viewDidLoad()
      //todo --- tillusory start1 ---
//      #error 添加TiSDK Key，与包名绑定，请与商务联系获取
      let key = ""
      TiSDK.shareInstance().initSDK(key, with: nil)
      //todo --- tillusory end1 ---
//      updateViews()
  }
}
