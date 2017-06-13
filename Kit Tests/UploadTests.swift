//
//  UploadTests.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
import Alba
@testable import TheGreatKit

class UploadTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSome() {
        let uploader = FavoriteTeamsUploader(rollback: jprint)
        let pub = Publisher<(FavoriteTeams.Update, Set<Team.ID>)>(label: "test")
        uploader.declare(didUpdateFavorites: pub.proxy)
        let ids = Set([1, 3, 10].flatMap(Team.ID.init))
        let update = FavoriteTeams.Update.init(teamID: ids.first!, isFavorite: true)
        pub.publish((update, ids))
        RunLoop.current.run()
    }
    
}
