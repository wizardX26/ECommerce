//
//  VTPSKWebView.swift
//  Authentication
//
//  Created by PhongTM on 12/7/20.
//  Copyright © 2020 ViettelPay App Team. All rights reserved.
//

import Foundation
import WebKit

public class VTPSKWebView: WKWebView {

	public init(frame: CGRect) {
		super.init(frame: frame, configuration: VTPSKWebView.config())
	}

   public init(scalableConfig isScalable: Bool, andAddTo parentView: UIView?) {
		super.init(frame: CGRect.zero, configuration: VTPSKWebView.config(withScalable: isScalable))
		add(to: parentView)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	static func config(withScalable isScalable: Bool = true) -> WKWebViewConfiguration {
		let userContentController = WKUserContentController()

		let conf = WKWebViewConfiguration()

		conf.userContentController = userContentController
		if !isScalable {
			let source = """
					var meta = document.createElement('meta');\
					meta.name = 'viewport';\
					meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=YES';\
					var head = document.getElementsByTagName('head')[0];head.appendChild(meta);
					"""

			let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
			userContentController.addUserScript(script)
		}

		return conf
	}

	func add(to parentView: UIView?) {
		if let parentView = parentView {
			parentView.addSubview(self)
			// add contraints for webview
			translatesAutoresizingMaskIntoConstraints = false

			let leadingingConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: parentView, attribute: .leading, multiplier: 1, constant: 0)

			let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)

			let traillingConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: parentView, attribute: .trailing, multiplier: 1, constant: 0)

			let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: parentView, attribute: .bottom, multiplier: 1, constant: 0)

			parentView.addConstraints([topConstraint, leadingingConstraint, traillingConstraint, bottomConstraint])
		}

	}
}
