//
//  RoomMembers.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

/// Cette structure contient une liste de ``RoomMember``.
public struct RoomMembers : Codable {
	/// La liste des ``RoomMember``.
	public let roomMembers : [RoomMember]?

	enum CodingKeys: String, CodingKey {
		case roomMembers = "chunk"
	}

	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		roomMembers = try values.decodeIfPresent([RoomMember].self, forKey: .roomMembers)
	}
}
