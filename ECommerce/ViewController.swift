//
//  ViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("✅ Available languages: \(Localize.availableLanguages())")
        print("✅ Current language: \(Localize.currentLanguage())")
        print("✅ Welcome: \("welcome".localized())")
    }


}

