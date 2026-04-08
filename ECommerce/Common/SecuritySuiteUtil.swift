////
////  SecuritySuiteUtil.swift
////  DOTP
////
////  Created by chanhbv on 03/08/2022.
////
//
//import Foundation
//import SecuritySuite
//import RxSwift
//import CoreUtilsKit
//import RxCocoa
//
//struct SecuritySuiteModel {
//	var isAllowSmartOTP: Bool?
//	var isAllowBio: Bool?
//}
//
//class SecuritySuiteUtil {
//	
//	var fake: Bool = false
//	var securedModel: SecuritySuiteModel = SecuritySuiteModel()
//    
//	func isSecure(byPassDev: Bool = false, unsecured: @escaping () -> Void, secured: @escaping () -> Void) {
//        SecurityAction.shared.configure(isActiveChecker: !byPassDev)
//        SecurityAction.shared.execute { status in
//            let jailBreakStatus = status.jailBreakStatus?.jailBroken ?? false
//            let isRunEmulator = status.isRunEmulator ?? false
//            let isDebugged = status.isDebugged ?? false
//            let isReverseEngineered = status.isReverseEngineered ?? false
//            let tamperResult = status.tamperResult?.result ?? false
//            let isProxied = status.isProxied ?? false
//
//            if jailBreakStatus || isRunEmulator || isDebugged || isReverseEngineered || tamperResult || isProxied {
//                unsecured()
//            } else {
//                secured()
//            }
//        }
//    }
//
//	func checkDevice() -> Observable<SecuritySuiteModel?> {
//		return Observable.combineLatest(isAllowSmartOTP().asObservable(), isAllowBio().asObservable())
//			.flatMap({[weak self] (isAllowSmartOTP, isAllowBio) -> Observable<SecuritySuiteModel?> in
//				self?.securedModel.isAllowSmartOTP = isAllowSmartOTP
//				self?.securedModel.isAllowBio = isAllowBio
//				return Observable.of(self?.securedModel)
//			})
//	}
//	
//	func isAllowSmartOTP() -> Single<Bool> {
//		return Single<Bool>.create { [weak self] single in
//			if self?.fake == true {
//				single(.success(true))
//				return Disposables.create()
//			}
//			
//			if let isSecured = self?.securedModel.isAllowSmartOTP {
//				single(.success(isSecured))
//			} else if #available(iOS 10, *) {
//				var isBypassDev = false
//				if !CommonUtil.shared.isStoreBundle() {
//					#if DEBUG
//					isBypassDev = true
//					#endif
//				}
//				self?.isSecure(byPassDev: isBypassDev) {
//					single(.success(false))
//				} secured: {
//					single(.success(true))
//				}
//			} else {
//				single(.success(false))
//			}
//			return Disposables.create()
//		}
//	}
//	
//	func isAllowBio() -> Single<Bool> {
//		return Single<Bool>.create { single in
//			single(.success(false))
//			return Disposables.create()
//		}
//	}
//}
