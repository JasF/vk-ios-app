//
//  ViewController.swift
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit
import Async_DisplayKit

class ViewController: UIViewController, A_STableDataSource, A_STableDelegate {

  var tableNode: A_STableNode


  // MARK: UIViewController.

  override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.tableNode = A_STableNode()

    super.init(nibName: nil, bundle: nil)

    self.tableNode.dataSource = self
    self.tableNode.delegate = self
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("storyboards are incompatible with truth and beauty")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(self.tableNode.view)
  }

  override func viewWillLayoutSubviews() {
    self.tableNode.frame = self.view.bounds
  }


  // MARK: A_STableView data source and delegate.

  func tableNode(_ tableNode: A_STableNode, nodeForRowAt indexPath: IndexPath) -> A_SCellNode {
    let patter = NSString(format: "[%ld.%ld] says hello!", indexPath.section, indexPath.row)
    let node = A_STextCellNode()
    node.text = patter as String

    return node
  }

  func numberOfSections(in tableNode: A_STableNode) -> Int {
    return 1
  }

  func tableNode(_ tableNode: A_STableNode, numberOfRowsInSection section: Int) -> Int {
    return 20
  }

}
