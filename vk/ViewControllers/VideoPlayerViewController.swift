//
//  VideoPlayerViewController.swift
//  vk
//
//  Created by Jasf on 29.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import WebKit

@objcMembers class VideoPlayerViewController : UIViewController {
    let viewModel: VideoPlayerViewModel?
    convenience init() {
        self.init(nil)
    }
    
    public init(_ viewModel: VideoPlayerViewModel?) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.viewModel = nil
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
    }
}
