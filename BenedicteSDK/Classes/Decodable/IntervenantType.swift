//
//  IntervenantType.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 04/10/2023.
//

import Foundation

struct IntervenantType: Decodable {
	let idBot: String
	let idConseiller: String
	let idInvite: String
	let idUsager: String
	
	enum CodingKeys: String, CodingKey {
		case idBot = "idBot"
		case idConseiller = "idConseiller"
		case idInvite = "idInvite"
		case idUsager = "idUsager"
	}
}
