//
//  ConnectionConfiguration.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

struct ConnectionConfiguration: Decodable {
	let userId: String
	let IDToken: String
	
	enum CodingKeys: String, CodingKey {
		case userId = "userId"
		case IDToken = "accessToken"
	}
}
