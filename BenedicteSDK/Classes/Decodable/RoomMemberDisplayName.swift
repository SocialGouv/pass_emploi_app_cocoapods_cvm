//
//  RoomMemberDisplayName.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

/// Cette structure contient le nom de l'utilisateur.
public struct RoomMemberDisplayName : Codable {
	/// Le nom de l'utilisateur.
	public let displayName : String?

	enum CodingKeys: String, CodingKey {
		case displayName = "displayname"
	}

	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
	}
}
