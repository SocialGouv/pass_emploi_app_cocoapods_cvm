//
//  ConnectionService.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation
import Alamofire
import ADEUMInstrumentation

class ConnectionService {
	static let sharedInstance = ConnectionService()
	
	// Constants
	let TYPEAUTH = "typeAuth"
	let INDIVIDU = "/individu"
	
	func getMatrixAccessToken(accessToken:String, authServerUrl:String, completion: @escaping(Bool) -> Void) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		let httpTracker = ADEumHTTPRequestTracker(url: URL(string: authServerUrl)!)
		
		let headers: HTTPHeaders = [
			"Authorization": "Bearer " + accessToken,
			TYPEAUTH: INDIVIDU
		]
		
		MatrixManager.sharedInstance.alamofireSession!.request(authServerUrl, headers: headers).responseDecodable(of: ConnectionConfiguration.self) { (response) in
			debugPrint("Response : \(response)")
			
			guard let session = response.value else {
				httpTracker.error = response.error
				
				completion(false)
				
				httpTracker.reportDone()
				ADEumInstrumentation.endCall(tracker)
				return
			}
			
			SessionManager.sharedInstance.userId = session.userId
			SessionManager.sharedInstance.accessToken = session.IDToken
			SessionManager.sharedInstance.homeServer = session.userId.components(separatedBy: ":").last
			
			completion(response.error == nil)
			
			httpTracker.statusCode = response.response?.statusCode as NSNumber?
			httpTracker.allHeaderFields = response.response?.allHeaderFields
			
			httpTracker.reportDone()
			ADEumInstrumentation.endCall(tracker)
		}
	}
}
