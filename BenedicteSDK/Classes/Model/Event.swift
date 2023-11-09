//
//  Message.swift
//  BenedicteSDK
//
//  Created by aperarnaud on 10/08/2022.
//

import Foundation

/// Un ``Event``est l'objet qui décrit un evènement reçu depuis le serveur de converation.
public class Event {
	/// Le texte d'un message écrit.
	public var message : String? = nil
	/// Cet un nouvel ``Event``.
	public var isNewEvent: Bool = true
	/// Le nom de l'utilisateur qui a envoyé le message.
	public var senderName: String? = nil
	/// L'identifiant de l'utilisateur qui a envoyé le message.
	public var senderID: String? = nil
	/// Le date de création du message
	public var date: Date? = nil
	/// L'identifiant de la pièce-jointe.
	public var attachmentID: String? = nil
	/// L'url de l'aperçu d'une pièce-jointe de type `m.image`.
	public var thumbnailUrl: String? = nil
	/// Indique si c'est un message de notification de saisie en cours.
	public var isTypingEvent: Bool = false
	/// Etat de la saisie en cours.
	public var typingState: TypingState? = .end
}

/// Les états de saisie disponibles.
public enum TypingState {
	case start
	case end
}
