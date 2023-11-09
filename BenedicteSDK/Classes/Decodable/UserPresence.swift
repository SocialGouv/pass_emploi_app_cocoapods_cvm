//
//  UserPresence.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 26/01/2023.
//

import Foundation

/// Cette structure décrit les informations de disponibilité d'un utilisateur.
public struct UserPresence : Codable {
	/// Indique si l'utilisateur est actif.
	public let isActive : Bool?
	/// Indique le temps depuis la dernière période d'activité.
	public let inactiveSince : Int?
	/// Indique un statut de présence [`online`, `offline`, `unavailable`].
	public let presenceStatus : String?
	/// Indique le message de statut personnalisé de l'utilisateur.
	public let statusMessage : String?
	
	enum CodingKeys: String, CodingKey {
		case isActive = "currently_active"
		case inactiveSince = "last_active_ago"
		case presenceStatus = "presence"
		case statusMessage = "status_msg"
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		isActive = try values.decodeIfPresent(Bool.self, forKey: .isActive)
		inactiveSince = try values.decodeIfPresent(Int.self, forKey: .inactiveSince)
		presenceStatus = try values.decodeIfPresent(String.self, forKey: .presenceStatus)
		statusMessage = try values.decodeIfPresent(String.self, forKey: .statusMessage)
	}
}
