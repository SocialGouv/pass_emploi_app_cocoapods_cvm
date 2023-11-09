//
//  SessionManager.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation

/// Ce manager contient les infos nécessaires à la création d'une session sur le serveur de conversation.
///
/// C'est un singleton dont l'accès se fait par l'objet ``SessionManager/sharedInstance`` de cette façon :
/// ```swift
/// SessionManager.sharedInstance.{NomDeLaMethode}
/// ```
public class SessionManager {
	/// L'instance en cours de ``SessionManager``
	public static let sharedInstance = SessionManager()
	
	/// L'identifiant de l'utilisateur connecté.
	public var userId: String! = nil
	/// L'accesToken de connexion au serveur.
	public var accessToken: String! = nil
	/// L'url du serveur de conversation.
	public var homeServer: String! = nil
	/// L'identifiant du device connecté.
	public var deviceId: String! = nil
	/// L'url du serveur de conversation.
	public var matrixServerBaseUrl: String! = nil
	
	func disconnect() {
		SessionManager.sharedInstance.accessToken = nil
		SessionManager.sharedInstance.userId = nil
		
		accessToken = nil
		userId = nil
		homeServer = nil
		deviceId = nil
	}
}
