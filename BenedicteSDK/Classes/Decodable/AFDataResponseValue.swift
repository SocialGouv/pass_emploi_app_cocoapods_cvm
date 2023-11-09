//
//  AFDataResponseValue.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 23/01/2023.
//

import Foundation

struct AFDataResponseValue: Decodable {
	let contentUri: String
	
	enum CodingKeys: String, CodingKey {
		case contentUri = "content_uri"
	}
}
