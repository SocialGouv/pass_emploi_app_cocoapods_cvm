# ``BenedicteSDK``

BenedicteSDK est un framework qui permet d'intégrer un module conversationnel dans une application iOS.

## Aperçu

BenedicteSDK fournit tous les modèles et outils pour créer et gérer un module conversationnel.

L'ensemble des fonctionnalités est proposé dans le manager ``MatrixManager``. C'est lui qui expose les méthodes utiles pour ouvrir une session, se connecter à une ``Room`` et envoyer ou recevoir des messages.

La connexion se fait par le biais d'un AccessToken passé au ``MatrixManager/loginAndStartSession(accessToken:oauthServer:completion:)`` qui retournera une session. L'``accessToken`` en paramètre est celui obtenu depuis la connexion PEConnect. L'``oauthServer`` est l'URL de l'ex160.

Une session est gérée par le ``SessionManager``.

Tous les messages (texte, pièce-jointe) sont des objets de type ``Event``.

## Guide de démarrage

Voici les étapes à suivre pour commencer à récupérer des messages venant du serveur. Du démarrage du SDK (étape 1) en passant par la connexion au serveur de discussion (étape 2) jusqu'à la réception des premiers messages (étape 5.2).

1. Initialisation du SDK :

	Le démarrage du SDK se fait par la méthode ``MatrixManager/initialize(paginationPageSize:)``. Le paramètre indique la pagination appliquée lors de la récupération de l'historique des messages.
	
2. Connexion au serveur de discussion : 

   Une fois en possession d'un ``accesToken`` PEConnect valide, il faut le passer en paramètre de la méthode ``MatrixManager/loginAndStartSession(accessToken:oauthServer:completion:)`` avec l'URL de l'ex160 en second paramètre. En retour, la méthode renvoie un Booléen indiquant une connexion reussie ou non.
3. Découverte et ouverture de la discussion : 
   1. Utiliser la méthode ``MatrixManager/joinFirstRoom(completion:)`` pour se connecter à la ``Room`` dédiée à l'utilisateur connecté. En cas d'échec, passer au point 3.2. En cas de succès, passer au 4.
   2. Démarrer une écoute de création de ``Room`` avec la méthode ``MatrixManager/startRoomListener(completion:)``. En retour, dès la création d'une ``Room`` dédiée à l'utilisateur connecté, la méthode entrera dans le ``completion:`` avec la liste des ``Room`` en paramètre. De là, vous pouvez stopper le lecteur de ``Room`` en utilisant la méthode ``MatrixManager/stopRoomListener()`` puis en revenant au point 3.1.
4. Accès à la discussion :
	
   Le point précédent, en succès, renvoie une ``Room`` en paramètre. Il faut conserver cette ``Room`` pour la suite.
5. Préparation à la réception des messages : 
	
   Il faut maintenant démarrer une écoute des ``Event`` qui arrivent dans cette ``Room``. 
   1. Pour ce faire, utilisez la méthode ``MatrixManager/startMessageListener(room:, newEvent:)`` en passant la ``Room`` en paramètre.
   2. Le completion ``newEvent`` sera déclenché à chaque nouvel évènement provenant du serveur de discussion et il sera de type ``Event``.
   3. Cf. la documentation de l'objet ``Event`` pour savoir ce que l'on peut en faire.

## Topics

### Managers essentiels

- ``MatrixManager``
- ``SessionManager``

### Modèles disponibles

- ``Room``
- ``Event``
- ``RoomMember``
- ``RoomMembers``
- ``RoomMemberDisplayName``

## Exemple

Pour lancer le projet d'exemple, clonez le repo et lancez la commande `pod install` depuis le répertoire Example.

## Installation

BenedicteSDK est un package au format [CocoaPods](https://cocoapods.org). Pour l'installer il suffit d'ajouter les lignes suivantes dans votre fichier `podfile`:

```ruby
pod 'BenedicteSDK'
```

De définir la platforme :
```ruby 
'platform :ios, '11.0'
```

Et d'ajouter les sources :
```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'URL du fichier pod-specs.git'
```

Au final, le `podfile` devrait ressembler à :

```ruby
# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'URL du fichier pod-specs.git'

target 'MonProjet' do
# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

# Pods for MonProjet
pod 'BenedicteSDK'
end
```

## Auteur

Mobile Factory, <d2iamobilefactory.00322@pole-emploi.fr>

## License

TBA
