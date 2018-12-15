//
//  GameScene.swift
//  BikeManPanorama
//
//  Created by Kohei Arai on 2018/12/14.
//  Copyright © 2018年 Kohei Arai. All rights reserved.
//

import SpriteKit
import GameplayKit

final class GameScene: SKScene {
    
    //SK objects
    private var bikeMan: SKSpriteNode?
    private var defaultGround: SKSpriteNode?
    
    //parameters
    private var groundList = [(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)]()
    private var isGameStarted = false
    private var defaultGroundTimer: Timer?
    
    //constants
    private let numberOfGround = 100
    private let gWidthMin = 300
    private let gWidthMax = 500
    private let gHeightMin = 500
    private let gHeightMax = 800
    private let gDiffMin = 0
    private let gDiffMax = 200
    private lazy var gStart: CGFloat = -size.width / 2 + defaultGround!.size.width + 500
    private let scrollSpeed = 300.0
    
    override func didMove(to view: SKView) {
        createBackground()
        bikeMan = childNode(withName: "bikeMan") as? SKSpriteNode
        bikeMan?.zPosition = 1
        defaultGround = childNode(withName: "defaultGround") as? SKSpriteNode
        createGroundListMock()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            isGameStarted = true
            startGame()
            return
        }
        jump()
    }
    
    private func startGame() {
        updateDefaultGround()
        createGround()
    }
    
    private func updateDefaultGround() {
        defaultGround?.physicsBody?.pinned = false
        defaultGround?.physicsBody?.affectedByGravity = false
    }
    
    private func jump() {
        bikeMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 25_000))
    }
    
    private func createBackground() {
        let background = SKSpriteNode(imageNamed: "mask")
        background.size.height = frame.size.height
        background.position = CGPoint(x: 0, y: 0)
        addChild(background)
    }
    
    private func createGround() {
        for (index, elem) in groundList.enumerated() {
            let gWidth = elem.maxX - elem.minX
            let gHeight = abs(elem.maxY - elem.minY)
            let gSize = CGSize(width: gWidth, height: gHeight)
            
            let ground = SKSpriteNode(color: .red, size: gSize)
            ground.physicsBody = SKPhysicsBody(rectangleOf: gSize)
            ground.physicsBody?.affectedByGravity = false
            ground.physicsBody?.isDynamic = false
            addChild(ground)
            
            let groundCX = elem.minX + gWidth / 2
            let groundCY = elem.minY - gHeight / 2
            ground.position = CGPoint(x: groundCX, y: groundCY)
            ground.zPosition = 1
            
            let moveGround = SKAction.moveBy(x: -gStart - groundCX - gWidth - gWidth * CGFloat(index), y: 0, duration: TimeInterval(gStart + groundCX + gWidth + gWidth * CGFloat(index)) / scrollSpeed)
            
            ground.run(moveGround)
        }
    }
    
    private func createGroundListMock() {
        let originalGStart = gStart
        for _ in 0..<numberOfGround {
            let gWidth = CGFloat(Int.random(in: gWidthMin..<gWidthMax))
            let gHeight = CGFloat(Int.random(in: gHeightMin..<gHeightMax))
            let gDiff = CGFloat(Int.random(in: gDiffMin..<gDiffMax))
            groundList.append((minX: gStart, minY: -size.height / 2 + gHeight, maxX: gStart + gWidth, maxY: -size.height / 2))
            gStart += gWidth + gDiff
        }
        gStart = originalGStart
    }
}
