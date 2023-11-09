//
//  MatrixManager.swift
//  BenedicteSDK
//
//  Created by Pole Emploi on 19/01/2023.
//

import Foundation
import MatrixSDK
import Alamofire
import ADEUMInstrumentation

/// Ce manager est le point d'entrée du SDK.
///
/// C'est un singleton dont l'accès se fait par l'objet ``MatrixManager/sharedInstance`` de cette façon :
///
/// ```swift
///	MatrixManager.sharedInstance.{NomDeLaMethode}
/// ```
///
/// Il est essentiel de le configurer avant toute utilisation, dans votre AppDelegate par exemple.
///
/// La configuration se fait en utilisant soit :
/// - si vous voulez utiliser AppDynamics pour tracer votre application ``configure(appDynamicsKey:paginationPageSize:)``
/// - ou ``configure(paginationPageSize:)`` de cette façon :
///
/// ```swift
/// MatrixManager.sharedInstance.configure(appDynamicsKey: "XX-XXX-XXX", paginationPageSize: 20)
/// MatrixManager.sharedInstance.configure(paginationPageSize: 20)
/// ```
///
/// L'accès au manager depuis l'application ce fait par l'objet ``MatrixManager/sharedInstance``
public class MatrixManager {
	// MARK: - Contants
	
	let INT32MAX = 2147483647
	
	// MARK: - Public properties
	
	/// L'instance en cours de ``MatrixManager``.
	public static let sharedInstance = MatrixManager()
	/// Indique si il reste des messages à récupérer dans l'historique d'une conversation.
	public var hasMoreMessages: Bool!
	/// Indique si une session ``SessionManager``est en cours.
	public var hasSession: Bool!
	/// Cette Session doit être utilisée si l'application utilise Alamofire comme client HTTP.
	public var alamofireSession: Session?
	
	// MARK: - Private variables
	
	var mxSession: MXSession!
	var mxRestClient: MXRestClient!
	var listenerRef: [String : Any] = [:]
	var sender: String!
	var roomState: MXRoomState!
	var roomListener: Any!
	var paginationSize: Int! = 20
	var transactionIdCount: Int = 0
	
	// MARK: - Public functions
	
	/// Permet de configurer le SDK avec une clé AppDynamics au format XX-XXX-XXX.
	/// Doit être appelé au plus tôt dans l'application (AppDelegate.swift est un bon endroit).
	///
	/// Utilisation :
	/// ```swift
	/// func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
	/// 	// Override point for customization after application launch.
	/// 	MatrixManager.sharedInstance.initialize(appDynamicsKey: "XX-XXX-XXX", paginationPageSize: 20)
	///
	///		return true
	/// }
	/// ```
	///
	/// - Parameters:
	///   - appDynamicsKey: la clé application pour AppDynamics au format XX-XXX-XXX.
	///   - paginationPageSize: la taille de pagination d'une discussion.
	public func initialize(appDynamicsKey: String, paginationPageSize: Int) {
		let alamofireConfiguration = URLSessionConfiguration.af.default
		alamofireSession = Session(configuration: alamofireConfiguration)
		
		let appDynamicsConfiguration = ADEumAgentConfiguration(appKey: appDynamicsKey, collectorURL: "https://fra-col.eum-appdynamics.com")
		appDynamicsConfiguration.crashReportingEnabled = true
		appDynamicsConfiguration.interactionCaptureMode = ADEumInteractionCaptureMode.ADEumInteractionCaptureModeAll
		appDynamicsConfiguration.loggingLevel = .all
		ADEumInstrumentation.initWith(appDynamicsConfiguration)
		
		self.paginationSize = paginationPageSize
	}
	
	/// Permet de configurer le SDK.
	/// Doit être appelé au plus tôt dans l'application (AppDelegate.swift est un bon endroit).
	///
	/// Utilisation :
	/// ```swift
	/// func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
	/// 	// Override point for customization after application launch.
	/// 	MatrixManager.sharedInstance.initialize(paginationPageSize: 20)
	///
	///		return true
	/// }
	/// ```
	///
	/// - Parameter paginationPageSize: la taille de pagination d'une discussion.
	public func initialize(paginationPageSize: Int) {
		self.initialize(appDynamicsKey: "EC-AAB-WZT", paginationPageSize: paginationPageSize)
	}
	
	/// Permet de se connecter au serveur de conversation en utilisant un identifiant et un mot de passe.
	///
	/// Utilisation :
	///	```swift
	///	MatrixManager.sharedInstance.loginAndStartSessionWithUsernameAndPassword(
	///		login: AppSettings.userId!,
	///		password: AppSettings.password!,
	///		matrixServer: AppSettings.matrixServer!,
	///		completion: { () -> () in
	/// 		// Votre code içi
	/// 	})
	///	```
	///
	/// - Parameters:
	///   - login: l'identifiant de connexion.
	///   - password: le mot de passe.
	///   - matrixServer: l'url du serveur de conversation.
	///   - completion: le callback exécuté à la fin d'une connexion réussie.
	public func loginAndStartSessionWithUsernameAndPassword(login: String, password: String, matrixServer: String, completion:@escaping () -> ()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		
		mxRestClient = MXRestClient(homeServer: URL(string: "https://\(matrixServer)")!, unrecognizedCertificateHandler: nil)
		
		let params = [
			"type": "m.login.password",
			"password": password,
			"user": login
		]
		
		request("https://\(matrixServer)/_matrix/client/v3/login", method: "post", parameters: params, completion: {
			response in
			switch response {
				case .success(let value):
					debugPrint("Response : \(value)")
					do {
						let sessionConfiguration = try JSONDecoder().decode(SessionConfiguration.self, from: value as! Data)
						SessionManager.sharedInstance.userId = sessionConfiguration.userId
						SessionManager.sharedInstance.accessToken = sessionConfiguration.accessToken
						SessionManager.sharedInstance.homeServer = sessionConfiguration.homeServer
						SessionManager.sharedInstance.deviceId = sessionConfiguration.deviceId
						
						self.startSession {
							completion()
							ADEumInstrumentation.endCall(tracker)
						}
					} catch {
						debugPrint("Error while parsing JSON : \(error)")
						ADEumInstrumentation.endCall(tracker)
					}
				case .failure(_):
					ADEumInstrumentation.endCall(tracker)
			}
		})
	}
	
	/// Permet de se connecter au serveur de conversation en utilisant un AccessToken PEConnect.
	///
	/// Utilisation.
	/// ```swift
	///	MatrixManager.sharedInstance.loginAndStartSession(
	///		accessToken: OAuth2SessionManager.sharedInstance.OAuth2AccessToken.accessToken!,
	///		oauthServer: oauth2Configuration.Ex160,
	///		completion: { () -> () in
	///			//  Votre code içi
	///		})
	/// ```
	///
	/// - Parameters:
	///   - accessToken: l'AccessToken d'identification obtenu de PEConnect.
	///   - oauthServer: l'url du serveur de conversation (ex160).
	///   - completion: le callback exécuté à la fin d'une connexion réussie.
	public func loginAndStartSession(accessToken:String, oauthServer: String, completion:@escaping (Bool) -> ()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		
		ConnectionService.sharedInstance.getMatrixAccessToken(accessToken:accessToken, authServerUrl: oauthServer, completion: {
			response in
			debugPrint("Response : \(response)")
			
			if response == true {
				self.startSession {
					completion(true)
					ADEumInstrumentation.endCall(tracker)
				}
			} else {
				completion(false)
				ADEumInstrumentation.endCall(tracker)
			}
		})
	}
	
	/// Permet d'obtenir le ``SessionManager`` en cours.
	///
	/// Utilisation :
	/// ```swift
	///	let session = MatrixManager.sharedInstance.getSession()
	/// ```
	///
	/// - Returns: l'instance de ``SessionManager`` utilisée.
	public func getSession() -> SessionManager {
		return SessionManager.sharedInstance
	}
	
	/// Met fin à la Session en cours.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.stopSession()
	/// ```
	public func stopSession() {
		mxSession?.close()
		mxRestClient?.close()
		getSession().disconnect()
		
		hasSession = false
		
		mxSession = nil
		mxRestClient = nil
		roomListener = nil
	}
	
	/// Démarre l'écoute du listing des ``Room``.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.startRoomListener(
	/// 	completion: { rooms in
	/// 		if (rooms != nil && rooms?.isEmpty == false) {
	///				// Votre code içi
	/// 		}
	/// 	})
	/// ```
	///
	/// - Parameter completion: le callback contenant la liste des ``Room`` disponibles.
	public func startRoomListener(completion:@escaping ([Room]?) -> ()) {
		if (self.hasSession != nil && self.hasSession) {
			roomListener = self.mxSession.listenToEvents { event, direction, customObject in
				let rooms = self.getRooms()
				completion(rooms)
			}
		}
	}
	
	/// Arrête l'écoute du listing des ``Room``.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.stopRoomListener()
	/// ```
	public func stopRoomListener() {
		self.mxSession?.removeListener(roomListener)
	}
	
	/// Permet de se connecter à la première ``Room`` disponible.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.joinFirstRoom(
	/// 	completion: { room in
	/// 		if (room != nil) {
	///				// Votre code içi
	///			}
	///		})
	/// ```
	///
	/// - Parameter completion: le callback qui retourne la ``Room`` connectée. Retourne `nil` si la connexion échoue.
	public func joinFirstRoom(completion:@escaping (Room?) -> ()) {
		if (self.hasSession != nil && self.hasSession) {
			let rooms = self.getRooms()
			
			if (rooms?.isEmpty == true) {
				completion(nil)
			} else {
				autoJoinRoom(rooms![0], completion: { response in
					if response {
						completion(rooms![0])
					} else {
						completion(nil)
					}
				})
			}
		} else {
			completion(nil)
		}
	}
	
	/// Demande la récupération de l'historique des messages.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.loadMoreMessage(
	/// 	room: room,
	/// 	completion: {
	///			// Votre code içi
	///		})
	/// ```
	///
	/// - Parameters:
	///   - room: la ``Room`` sur laquelle on demande l'historique.
	///   - withPaginationSize: le nombre d'``Event`` à charger.
	///   - completion: le callback une fois l'historique disponible.
	public func loadMoreMessage(room: Room, withPaginationSize: Int = 20, completion:@escaping () -> ()) {
		let mxRoom:MXRoom = mxSession.room(withRoomId: room.id)
		
		mxRoom.liveTimeline { timeline in
			self.paginate(timeline, roomId: room.id, completion: { completion() })
		}
	}
	
	/// Démarre une écoute des messages reçus sur une ``Room``.
	///
	/// Le callback de cette méthode sera appelé à chaque fois qu'un ``Event`` est reçu du serveur de conversation.
	/// Un ``Event`` peut-être un message textuel, un pièce-jointe, une information de saisie en cours,...
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.startMessageListener(
	/// 	room: room,
	/// 	newEvent:{
	/// 		event -> () in
	///			// Votre code pour traiter l'``Event``
	/// 	)}
	/// ```
	///
	/// - Parameters:
	///   - room: la ``Room`` en écoute.
	///   - newEvent: le callback renvoyé par chaque nouvel ``Event`` reçu du serveur.
	public func startMessageListener(room : Room, newEvent:@escaping (Event) -> ()) {
		let mxRoom:MXRoom = mxSession.room(withRoomId: room.id)
		
		mxRoom.liveTimeline { timeline in
			timeline?.resetPagination()
			
			self.paginate(timeline, roomId: room.id, completion: {})
		}
		
		mxRoom.state { roomState in
			self.roomState = roomState
		}
		
		let ref = mxRoom.listen { event, direction, state in
			if (event.eventType == .roomMessage) {
				let evt = Event()
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "d/M/y à HH:mm"
				
				evt.senderName = self.roomState?.members.memberName(event.sender)
				evt.senderID = event.sender
				evt.message = event.content["body"] as? String
				evt.isNewEvent = direction == MXTimelineDirection.forwards
				evt.date = Date().adding(milliseconds: -Int(event.age))
				evt.isTypingEvent = false
				evt.typingState = .end
				
				if (event.isMediaAttachment()) {
					if let content = event.content["url"] as? String {
						evt.attachmentID = String(content.split(separator: "/").last ?? "")
					}
					
					if let msgType = event.content["msgtype"] as? String {
						if msgType == "m.image" {
							if let info = event.content["info"] as? Dictionary<String, Any> {
								evt.thumbnailUrl = info["thumbnail_url"] as? String
							}
						}
					}
				}
				
				if (evt.message?.isEmpty == false) {
					newEvent(evt)
				}
			}
			
			if (event.eventType == .typingNotification) {
				let evt = Event()
				
				evt.isTypingEvent = true
				
				if ((event.content["user_ids"] as! NSArray).count > 0) {
					evt.senderID = ((event.content["user_ids"] as! NSArray)[0] as! String)
					
					if evt.senderID != self.mxSession.myUserId {
						evt.senderName = self.roomState?.members.memberName(evt.senderID)
						evt.typingState = .start
					} else {
						return
					}
				} else {
					evt.senderID = nil
					evt.senderName = nil
					evt.typingState = .end
				}
				
				newEvent(evt)
			}
		}
		
		listenerRef[room.id] = ref
	}
	
	/// Arrête l'écoute d'une ``Room``.
	///
	/// Il n'y aura plus aucun ``Event`` reçu depuis cette ``Room``.
	///
	/// ```swift
	/// MatrixManager.sharedInstance.startMessageListener(
	/// 	room: room)
	/// ```
	///
	/// - Parameter room: la ``Room`` que l'on ne souhaite plus écouter.
	public func stopMessageListener(room : Room) {
		let mxRoom:MXRoom? = self.mxSession.room(withRoomId: room.id)
		let ref = listenerRef[room.id]
		
		mxRoom!.removeListener(ref)
	}
	
	/// Permet d'envoyer un message sur une ``Room``.
	///
	/// Cette méthode peut envoyer indifférement un texte ou une pièce-jointe selon les paramêtres renseignés.
	///
	/// Utilisation :
	/// ```swift
	/// // Envoyer un message texte
	/// MatrixManager.sharedInstance.sendMessage(room: room, message: myMessage, completion: {(successed) -> () in
	/// 		// Votre code içi
	/// 	})
	///
	/// // Envoyer une pièce-jointe
	/// MatrixManager.sharedInstance.sendMessage(room: room, body: myURL, filename: URL(string: myFileName)!, completion: {(successed) -> () in
	/// 		// Votre code içi
	/// 	})
	/// ```
	///
	/// - Parameters:
	///   - room: la ``Room`` sur laquelle envoyer le message.
	///   - message: le texte du message. `nil` pour l'envoi d'une pièce-jointe.
	///   - body: l'url de la pièce-jointe. `nil`pour l'envoi d'un texte.
	///   - filename: le nom de la pièce-jointe. `nil` pour l'envoi d'un texte.
	///  - Parameter completion: le callback appelé à la fin de l'envoi du message.
	///  - Parameter success:`true` si l'envoie a réussi. `false` sinon.
	public func sendMessage(room: Room, message:String? = nil, body: URL? = nil, filename: URL? = nil, completion:@escaping (_ success:Bool)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		if body == nil {
			postTestMessage(room: room, message: message!, completion: { response in
				completion(response)
				ADEumInstrumentation.endCall(tracker)
			})
		} else {
			sendUploadMessage(room: room, body: body!, filename: filename!, completion: { response in
				completion(response)
				ADEumInstrumentation.endCall(tracker)
			})
		}
	}
	
	/// Indique à une ``Room`` si l'utilisateur est en train de saisir du texte.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.sendIsTyping(room: room, typing: true, timeout: 1.0)
	/// ```
	///
	/// - Parameters:
	///   - room: la ``Room``a informé.
	///   - typing: indique si une saisie est en cours.
	///   - timeout: l'interval de temps d'inactivité avant de considérer une saisie arrêtée.
	public func sendIsTyping(room: Room, typing: Bool, timeout: TimeInterval?) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		
		if hasSession {
			let mxSession = getSession();
			
			let params = [
				"typing": typing,
				"timeout": timeout!.milliseconds
			] as [String : AnyObject]
			
			request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/rooms/\(room.id!)/typing/\(mxSession.userId!)", method: "put", parameters: params, completion: {
				response in debugPrint("Response : \(response)")
				
				ADEumInstrumentation.endCall(tracker)
			})
		}
	}
	
	/// Demande le téléchargement d'une pièce-jointe.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.downloadAttachment(attachmentFile, progression: { progress, attachmentID in
	/// 	// Code durant la progression du téléchargement
	///	}, completion: { complete in
	///		// Code à la fin du téléchargement
	/// })
	/// ```
	///
	/// - Parameters:
	///   - attachmentID: l'identifiant de la pièce-jointe sur le serveur de conversation.
	///   - destination: le chemin vers lequel stocker la pièce-jointe.
	///   - progression: le callback qui est appelé durant le téléchargement. Retourne un objet `Progress` qui contient le pourcentage d'avancement.
	///   - completion: le callback qui est appelé à la fin du téléchargement. Retourne le chemin de sauvegarde de la pièce-jointe.
	public func downloadAttachment(_ attachmentID:String, to destination:DownloadRequest.Destination? = nil, progression:@escaping (Progress, String)->(), completion:@escaping (AFDownloadResponse<URL?>)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		let httpTracker = ADEumHTTPRequestTracker(url: URL(string: "https://\(SessionManager.sharedInstance.homeServer!)/_matrix/media/v3/download/\(SessionManager.sharedInstance.homeServer!)/\(attachmentID)")!)
		
		let donwloadDestination: DownloadRequest.Destination
		if (destination == nil) {
			donwloadDestination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory, in: .userDomainMask, options: .removePreviousFile)
		} else {
			donwloadDestination = destination!
		}
		
		alamofireSession!.download(
			"https://\(SessionManager.sharedInstance.homeServer!)/_matrix/media/v3/download/\(SessionManager.sharedInstance.homeServer!)/\(attachmentID)",
			method: .get,
			encoding: JSONEncoding.default,
			headers: nil,
			to: donwloadDestination).downloadProgress(closure: { (progress) in
				progression(progress, attachmentID)
			}).response(completionHandler: { (defaultDownloadResponse) in
				completion(defaultDownloadResponse)
				
				httpTracker.statusCode = defaultDownloadResponse.response?.statusCode as NSNumber?
				httpTracker.allHeaderFields = defaultDownloadResponse.response?.allHeaderFields
				httpTracker.reportDone()
				ADEumInstrumentation.endCall(tracker)
			})
	}
	
	/// Demande le téléversement d'une pièce-jointe.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.uploadAttachment(myURL,
	/// 	progression: { progress in
	///		}, completion: { completion in
	///		}, failure: { failure in
	///	})
	/// ```
	///
	/// - Parameters:
	///   - file: l'url du fichier à téléverser.
	///   - progression: le callback durant le chargement. Retourne un objet `Progress` qui contient le pourcentage d'avancement.
	///   - completion: le callback en fin de chargement réussi.
	///   - failure: le callback si une erreur se produit.
	public func uploadAttachment(_ file: URL, progression:@escaping (Progress)->(), completion:@escaping (String)->(), failure:@escaping (AFError)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		let httpTracker = ADEumHTTPRequestTracker(url: URL(string: "https://\(SessionManager.sharedInstance.homeServer!)/_matrix/media/v3/upload")!)
		
		let headers: HTTPHeaders = [
			"Authorization": "Bearer " + getSession().accessToken
		]
		
		alamofireSession!.upload(file, to:"https://\(SessionManager.sharedInstance.homeServer!)/_matrix/media/v3/upload", headers: headers)
			.uploadProgress {
				progress in
				debugPrint("Response : \(progress)")
				progression(progress)
			}
			.responseDecodable(of: AFDataResponseValue.self, completionHandler: {
				response in
				debugPrint("Response : \(response)")
				
				guard response.error == nil else {
					httpTracker.error = response.error
					failure(response.error!)
					
					httpTracker.reportDone()
					ADEumInstrumentation.endCall(tracker)
					
					return
				}
				
				httpTracker.statusCode = response.response?.statusCode as NSNumber?
				httpTracker.allHeaderFields = response.response?.allHeaderFields
				
				completion(response.value!.contentUri)
				
				httpTracker.reportDone()
				ADEumInstrumentation.endCall(tracker)
			})
		
	}
	
	/// Permet d'obtenir le pseudonyme d'un utilisateur.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.getMemberName(userId: (partner?.userId)!,
	/// 	completion: { username -> () in })
	/// ```
	///
	/// - Parameters:
	///   - userId: l'identifiant de l'utilisateur.
	///   - completion: le callback appelé avec le nom en retour.
	public func getMemberName(userId: String, completion:@escaping (String)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/profile/\(userId)", method: "get", parameters: nil, completion: { response in
			switch response {
				case .success(let value):
					debugPrint("Response : \(value)")
					do {
						let roomMember = try JSONDecoder().decode(RoomMemberDisplayName.self, from: value as! Data)
						completion(roomMember.displayName!)
						ADEumInstrumentation.endCall(tracker)
					} catch {
						debugPrint("Error while parsing JSON : \(error)")
						ADEumInstrumentation.endCall(tracker)
					}
				case .failure(_):
					ADEumInstrumentation.endCall(tracker)
			}
		})
	}
	
	/// Permet d'obtenir la liste des utilisateur d'une ``Room``.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.getRoomMembers(self.room,
	/// 	completion: { allMembers in
	/// })
	/// ```
	///
	/// - Parameters:
	///   - room: la ``Room``.
	///   - completion: le callback avec un objet ``RoomMembers`` contenant la liste des utilisateur.
	public func getRoomMembers(_ room: Room, completion:@escaping (RoomMembers) -> ()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/rooms/\(room.id!)/members", method: "get", parameters: nil, completion: { response in
			switch response {
				case .success(let value):
					debugPrint("Response : \(value)")
					do {
						let roomMembers = try JSONDecoder().decode(RoomMembers.self, from: value as! Data)
						completion(roomMembers)
						ADEumInstrumentation.endCall(tracker)
					} catch {
						debugPrint("Error while parsing JSON : \(error)")
						ADEumInstrumentation.endCall(tracker)
					}
				case .failure(_):
					ADEumInstrumentation.endCall(tracker)
			}
		})
	}
	
	/// Permet d'obtenir des informations sur la disponibilité d'un utilisateur.
	///
	/// Utilisation :
	/// ```swift
	/// MatrixManager.sharedInstance.getUserPresence(userId, completion: { userPresence in })
	/// ```
	///
	/// - Parameters:
	///   - userId: l'identifiant de l'utilisateur.
	///   - completion: en callback, l'objet ``UserPresence``de cet utilisateur.
	public func getUserPresence(_ userId: String!, completion:@escaping (UserPresence) -> ()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/presence/\(userId!)/status", method: "get", parameters: nil, completion:
					{
			response in debugPrint("Response : \(response)")
			switch response {
				case .success(let value):
					do {
						let presence = try JSONDecoder().decode(UserPresence.self, from: value as! Data)
						completion(presence)
						ADEumInstrumentation.endCall(tracker)
					} catch {
						debugPrint("Error while parsing JSON : \(error)")
						ADEumInstrumentation.endCall(tracker)
					}
				case .failure(_):
					ADEumInstrumentation.endCall(tracker)
			}
			ADEumInstrumentation.endCall(tracker)
		})
	}
	
	// MARK: - Private functions
	
	func request(_ url: String, method: String, parameters: [String : Any]?, completion: @escaping (Result<Any, Error>) -> Void) {
		let httpTracker = ADEumHTTPRequestTracker(url: URL(string: url)!)
		
		let httpMethod = HTTPMethod(rawValue: method)
		let encoding: ParameterEncoding = httpMethod == .get ? URLEncoding.default : JSONEncoding.default
		if self.alamofireSession == nil { self.alamofireSession = Session.default }
		
		var headers: HTTPHeaders? = nil
		
		if (getSession().accessToken != nil) {
			headers = [
				"Authorization": "Bearer " + getSession().accessToken
			]
		}
		
		alamofireSession?.request(URL(string: url)!, method: httpMethod, parameters: parameters, encoding: encoding, headers: headers)
			.responseData { (response) in
				debugPrint("Response : \(response)")
				switch response.result {
					case .success(let data) :
						httpTracker.statusCode = response.response?.statusCode as NSNumber?
						httpTracker.allHeaderFields = response.response?.allHeaderFields
						
						completion(.success(data))
					case .failure(let error):
						httpTracker.error = error
						print(error)
						
				}
				httpTracker.reportDone()
			}
	}
	
	func getTransactionId() -> String {
		transactionIdCount += 1
		return String(format: "m%u.%tu", arc4random_uniform(UInt32(INT32MAX)), transactionIdCount)
	}
	
	func postTestMessage(room:Room, message:String, completion:@escaping (Bool)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		
		let params = [
			"body": message,
			"msgtype": "m.text"
		]
		
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/rooms/\(room.id!)/send/m.room.message/\(getTransactionId())", method: "put", parameters: params, completion: {
			response in
			switch response {
				case .success(let value):
					debugPrint("Response : \(value)")
					completion(true)
				case .failure(_):
					completion(false)
			}
			ADEumInstrumentation.endCall(tracker)
		})
	}
	
	func sendUploadMessage(room: Room, body: URL, filename: URL, completion:@escaping (Bool)->()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		let type = body.pathExtension
		var msgType: String = "m.file"
		
		switch type {
			case "png",
				"jpeg",
				"jpg",
				"bmp":
				msgType = "m.image"
				break
			case "pdf":
				msgType = "m.file"
				break
			case "doc",
				"docx",
				"txt":
				msgType = "m.text"
				break
			default:
				break
		}
		
		let uploadMessage = Message(filename: body.lastPathComponent, msgtype: msgType, url: filename)
		
		let params = [
			"body": uploadMessage.filename,
			"url": uploadMessage.url.absoluteString,
			"msgtype": uploadMessage.msgtype
		]
		
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/rooms/\(room.id!)/send/m.room.message/\(getTransactionId())", method: "put", parameters: params, completion: {
			response in
			switch response {
				case .success(let value):
					debugPrint("Response : \(value)")
					completion(true)
				case .failure(_):
					completion(false)
			}
			ADEumInstrumentation.endCall(tracker)
		})
	}
	
	func getRooms() -> [Room]? {
		var rooms : [Room] = []
		
		for mxRoom in mxSession!.rooms {
			var myRoomState:MXRoomState!
			mxRoom.state { roomState in
				myRoomState = roomState
			}
			
			let room : Room = Room()
			room.id = mxRoom.roomId
			room.name = mxRoom.summary.displayname
			room.invitedBy = myRoomState.members.memberName(mxRoom.summary.creatorUserId)
			room.isJoined = self.mxSession.isJoined(onRoom:mxRoom.roomId)
			
			rooms.append(room)
		}
		
		return rooms
	}
	
	fileprivate func paginate(_ timeline: MXEventTimeline?, roomId: String, completion:@escaping () -> ()) {
		timeline?.paginate(UInt(self.paginationSize), direction: MXTimelineDirection.backwards, onlyFromStore: false) { response in
			self.hasMoreMessages = timeline?.canPaginate(.backwards)
			
			completion()
		}
	}
	
	fileprivate func autoJoinRoom(_ room: Room, completion:@escaping (Bool)->()) {
		if !self.mxSession.isJoined(onRoom:room.id) {
			self.joinRoom(room: room, completion: { () in
				room.isJoined = true
				completion(true)
			})
		} else {
			room.isJoined = true
			completion(true)
		}
	}
	
	fileprivate func joinRoom(room:Room, completion:@escaping () -> ()) {
		let tracker = ADEumInstrumentation.beginCall(self, selector: #function)
		request("https://\(SessionManager.sharedInstance.homeServer!)/_matrix/client/v3/join/\(room.id!)", method: "post", parameters: nil, completion: {
			response in
			debugPrint("Response : \(response)")
			
			switch response {
				case .success(_) :
					completion()
				case .failure(let error):
					print(error)
					
			}
			ADEumInstrumentation.endCall(tracker)
		})
	}
	
	fileprivate func startSession(completion:@escaping () -> ()) {
		let credentials = MXCredentials(homeServer: "https://\(SessionManager.sharedInstance.homeServer!)",
										userId: SessionManager.sharedInstance.userId,
										accessToken: SessionManager.sharedInstance.accessToken)
		
		self.mxRestClient = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
		self.mxSession = MXSession(matrixRestClient: self.mxRestClient)
		
		self.mxSession.start { response in
			self.hasSession = true
			completion()
		}
	}
	
	fileprivate func jsonToData(from object:Any) -> Data? {
		guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
			return nil
		}
		return data
	}
	
	fileprivate func jsonToString(from object:Any) -> String? {
		guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
			return nil
		}
		return String(data: data, encoding: String.Encoding.utf8)
	}
	
	fileprivate func loadFileFromLocalPath(_ localFilePath: URL) ->Data? {
		return try? Data(contentsOf: localFilePath)
	}
}

extension Date {
	func adding(milliseconds: Int) -> Date {
		return Calendar.current.date(byAdding: .second, value: milliseconds / 1000, to: self)!
	}
}

extension TimeInterval {
	var milliseconds: Int {
		return Int(self * 1_000)
	}
}
