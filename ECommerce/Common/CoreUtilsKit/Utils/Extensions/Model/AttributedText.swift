//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

@objcMembers
public class AttributedText: NSObject {
    public var text: String?
    public var color: UIColor?
    public var font: UIFont?
    public var strokeColor: UIColor?
    public var strokeWidth: Double?
    
    public init(text: String, color: UIColor?, font: UIFont?) {
        self.text = text
        self.color = color
        self.font = font
    }
    
    public init(text: String, color: UIColor?, font: UIFont?, strokeColor: UIColor?, strokeWidth: Double?) {
        self.text = text
        self.color = color
        self.font = font
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }
}
