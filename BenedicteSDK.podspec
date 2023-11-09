#
# Be sure to run `pod lib lint BenedicteSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             = 'BenedicteSDK'
	s.version          = '1.0.31'
	s.summary          = 'BenedicteSDK fournit tous les modèles et outils pour créer et gérer un module conversationnel.'
	
	# This description is used to generate tags and improve search results.
	#   * Think: What does it do? Why did you write it? What is the focus?
	#   * Try to keep it short, snappy and to the point.
	#   * Write the description between the DESC delimiters below.
	#   * Finally, don't worry about the indent, CocoaPods strips it!
	
	s.description      = <<-DESC
	BenedicteSDK est un framework qui permet d'intégrer un module conversationnel dans une application iOS.
	L'ensemble des fonctionnalités est proposé dans le manager ``MatrixManager``. C'est lui qui expose les méthodes utiles pour ouvrir une session, se connecter à une ``Room`` et envoyer ou recevoir des messages.
	DESC
	
	s.homepage         = 'https://github.com/SocialGouv/pass_emploi_app_cocoapods_cvm'
	# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
	s.license          = { :type => 'MIT', :file => 'LICENSE' }
	s.author           = { 'Mobile Factory' => 'nicolas.brouillet@pole-emploi.fr' }
	s.source           = { :git => 'git@github.com:SocialGouv/pass_emploi_app_cocoapods_cvm.git', :tag => s.version.to_s }
	# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
	
	s.ios.deployment_target = '12.0'
	s.swift_version = '5.0'
	s.source_files = 'BenedicteSDK/Classes/**/*.swift'
	
	s.static_framework = true
	
	# s.resource_bundles = {
	#   'BenedicteSDK' => ['BenedicteSDK/Assets/*.png']
	# }
	
	# s.public_header_files = 'Pod/Classes/**/*.h'
	# s.frameworks = 'UIKit', 'MapKit'
	s.dependency 'Alamofire'
	s.dependency 'MatrixSDK'
	s.dependency 'AppDynamicsAgent'
end
