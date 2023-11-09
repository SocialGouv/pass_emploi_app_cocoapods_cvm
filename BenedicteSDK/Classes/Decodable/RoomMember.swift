//
//  RoomMember.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

/// Structure décrivant un utilisateur dans une ``Room``
public struct RoomMember : Codable {
	/// L'identifiant de l'utilisateur.
	public let userId : String?
	
	let content : RoomMemberDisplayName?

	enum CodingKeys: String, CodingKey {
		case content = "content"
		case userId = "user_id"
	}

	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		content = try values.decodeIfPresent(RoomMemberDisplayName.self, forKey: .content)
		userId = try values.decodeIfPresent(String.self, forKey: .userId)
	}
}
