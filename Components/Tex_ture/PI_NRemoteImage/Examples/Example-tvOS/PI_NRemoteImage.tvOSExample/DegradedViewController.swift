//
//  DegradedViewController.swift
//  PI_NRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PI_NRemoteImage

class DegradedViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        PI_NRemoteImageManager.shared().setShouldUpgradeLowQualityImages(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        imageView.pin_setImage(from: [
            URL(string: "https://placekitten.com/101/101")!,
            URL(string: "https://placekitten.com/401/401")!,
            URL(string: "https://placekitten.com/801/801")!
        ])
    }
}
