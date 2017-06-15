//
//  Application.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit
import Shallows

final class Application {
    
    let api: API
    let apiCache: APICache
    let images: Images
    let favoriteTeams: Favorites<Team.ID>
    let tokens: DeviceTokens
    let loggers: Loggers
    
    let watch: AppleWatch?
    let notifications: Notifications
    
    init() {
        self.loggers = Loggers()
        loggers.start()
        
        self.api = Application.makeAPI()
        self.apiCache = Application.makeAPICache()
        self.images = Images.inSharedCachesDirectory()
        self.tokens = DeviceTokens()
        self.favoriteTeams = Application.makeFavorites(tokens: tokens)
        self.watch = AppleWatch(favoriteTeams: favoriteTeams.registry.favoriteTeams)
        self.notifications = Notifications(application: UIApplication.shared)
        declare()
    }
    
    func declare() {
        tokens.declare(notifications: AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.proxy,
                       complication: watch?.pushKitReceiver.didRegisterWithToken.proxy ?? .empty())
        watch?.declare(didUpdateFavorites: favoriteTeams.registry.didUpdateFavorites)
        favoriteTeams.declare()
    }
    
    static func makeAPI() -> API {
        let server = launchArgument(.server) ?? .heroku
        switch server {
        case .github:
            let urlSession = URLSession(configuration: .default)
            printWithContext("Using github as a server")
            return API.gitHub(urlSession: urlSession)
        case .macBookSteve:
            printWithContext("Using this MacBook as a server")
            return API.macBookSteve()
        case .heroku:
            printWithContext("Using the-great-game-ruby.herokuapp.com as a server (Heroku)")
            return API.heroku()
        }
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Favorites<Team.ID> {
        return Favorites.inSharedDocumentsDirectory().make(tokens: tokens,
                                                           indicatorManager: .application,
                                                           shouldCheckUploadConsistency: AppDelegate.applicationDidBecomeActive.proxy.void().wait(seconds: 4.0))
    }
    
    static func makeAPICache() -> APICache {
        let cachingDisabled = launchArgument(.isCachingDisabled)
        if cachingDisabled {
            return APICache.inMemory()
        } else {
            return APICache.inSharedCachesDirectory()
        }
    }
    
}
