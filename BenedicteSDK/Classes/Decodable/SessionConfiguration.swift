//
//  SessionConfiguration.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

struct SessionConfiguration: Decodable {
	let userId: String
	let accessToken: String
	let homeServer: String
	let deviceId: String
	
	enum CodingKeys: String, CodingKey {
		case userId = "user_id"
		case accessToken = "access_token"
		case homeServer = "home_server"
		case deviceId = "device_id"
	}
}
