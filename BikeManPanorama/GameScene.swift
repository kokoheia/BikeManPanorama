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
    private var gameOverLabel: SKLabelNode?
    private var ceil: SKSpriteNode?
    private var play: SKSpriteNode?
    private var background: SKSpriteNode?
    
    //parameters
    private var groundList = [(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)]()
    private var isGameStarted = false
    
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
        setupNodesInGameScene()
//        createGroundListMock()
    }
    
    private func csvToArray() {
        if let csvPath = Bundle.main.path(forResource: "mask", ofType: "pickle") {
            do {
                let csvStr = try String(contentsOfFile:csvPath, encoding:String.Encoding.utf8)
                let csvArr = csvStr.components(separatedBy: .newlines)
                print(csvArr)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    private func setupNodesInGameScene() {
        bikeMan = childNode(withName: "bikeMan") as? SKSpriteNode
        bikeMan?.zPosition = 1
        defaultGround = childNode(withName: "defaultGround") as? SKSpriteNode
        ceil = childNode(withName: "ceil") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            isGameStarted = true
            startGame()
            return
        }
        
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let theNodes = nodes(at: location)
            for node in theNodes {
                if node.name == "play" {
                    resetGame()
                    return
                }
            }
        }
        jump()
    }
    
    private func resetGame() {
        NotificationCenter.default.post(name: .resetGameNotification, object: nil)
    }
    
    private func startGame() {
        updateDefaultGround()
        createGround()
    }
    
    private func gameOver() {
        scene?.isPaused = true
        
        gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel?.position = CGPoint(x: 0, y: 200)
        gameOverLabel?.fontSize = 100
        gameOverLabel?.zPosition = 1
        if let gameOverLabel = gameOverLabel {
            addChild(gameOverLabel)
        }
        
        play = SKSpriteNode(imageNamed: "play")
        play?.position = CGPoint(x: 0, y: -200)
        play?.name = "play"
        play?.zPosition = 1
        if let play = play {
            addChild(play)
        }
    }
    
    private func gameClear() {
        scene?.isPaused = true
        
        gameOverLabel = SKLabelNode(text: "Game Clear!")
        gameOverLabel?.position = CGPoint(x: 0, y: 200)
        gameOverLabel?.fontSize = 100
        gameOverLabel?.zPosition = 1
        if let gameOverLabel = gameOverLabel {
            addChild(gameOverLabel)
        }
        
        play = SKSpriteNode(imageNamed: "play")
        play?.position = CGPoint(x: 0, y: -200)
        play?.name = "play"
        play?.zPosition = 1
        if let play = play {
            addChild(play)
        }
    }
    
    
    private func updateDefaultGround() {
        defaultGround?.physicsBody?.pinned = false
        defaultGround?.physicsBody?.affectedByGravity = false
    }
    
    private func jump() {
        bikeMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 25_000))
    }
    
    private func createBackground() {
        background = SKSpriteNode(imageNamed: "mask")
        if let background = background {
            background.size.height = frame.size.height
            background.position = CGPoint(x: background.size.width / 2 - size.width / 2, y: 0)
            addChild(background)
            
            let moveGround = SKAction.moveBy(x: -background.size.width, y: 0, duration: TimeInterval(background.size.width) / scrollSpeed)
            background.run(moveGround)
        }
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
    
    override func update(_ currentTime: TimeInterval) {
        let gap: CGFloat = 100.0
        if let bikeMan = bikeMan {
            if bikeMan.position.x <= -size.width / 2 - gap || bikeMan.position.y <= -size.height / 2 - gap {
                gameOver()
            }
        }
        
        if let background = background {
//            print(background.position)
            if background.position.x <= -size.width / 2 - background.size.width / 2 + 1 {
                gameClear()
            }
        }
    }
}
