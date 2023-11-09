//
//  Room.swift
//  BenedicteSDK
//
//  Created by aperarnaud on 10/08/2022.
//

import Foundation

/// Classe décrivant une ``Room`` de discussion.
public class Room {
	/// L'identifiant de la ``Room``.
	public var id:String! = nil
	/// Le nom de la ``Room``.
	public var name:String! = nil
	/// Indique si l'utilisateur a rejoint la ``Room``.
	public var isJoined:Bool! = nil
	/// Identifiant de l'utilisateur qui a lancé l'invitation à la ``Room``.
    public var invitedBy:String! = nil
}
