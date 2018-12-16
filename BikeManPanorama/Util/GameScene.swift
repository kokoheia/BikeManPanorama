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
    private var line: SKShapeNode?
    private var movieBG: SKSpriteNode?
    private var countdownLabel: SKLabelNode?
    
    //parameters
    private var groundList = [(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)]()
    private var pointList = [CGPoint]()
    private var realStageList = [RealStage]()
    private var isGameStarted = false
    private var isAnimating = false
    
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
    private var magnification: CGFloat = 1
    private var lineXMax: CGFloat = 0
    private var lineXMin: CGFloat = 10000
    private var lineYMax: CGFloat = 0
    private var lineYMin: CGFloat = 10000
    private var count: Int = 3
    private var currentFrameCount = 0
    
    private let bikeManCategory: UInt32 = 0x1 << 1
    private let groundCategory: UInt32 = 0x1 << 2
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setupNodesInGameScene()
        createMovieBG()
        countdown(count: count)
    }
    
    private func getJSONData() throws -> Data? {
        guard let path = Bundle.main.path(forResource: "VID_cropped.max", ofType: "json") else { return nil }
        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
    
    private func createRealTimeLine() {
        guard let data = try? getJSONData() else { return }
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: [])
            guard let jsonArray = jsonResponse as? [[String: Any]] else {
                return
            }
            realStageList = jsonArray.map { (json) -> RealStage in
                let realStage = RealStage(img: json["img"] as! [Dictionary<String, Int>])
                return realStage
            }
            
            let cgPointList: [[CGPoint]] = realStageList.map({return $0.img.map({return CGPoint(x: CGFloat($0["x"] as! Int) * CGFloat(3.38) - CGFloat(self.size.width / 2), y: self.size.height - CGFloat($0["y"] as! Int) * CGFloat(3.38) - CGFloat(self.size.height / 2))})})
            
            createLine(with: cgPointList)
            
        } catch let parsingError {
            print("Error", parsingError)
        }
        let movieTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true, block: { (timer) in
            self.self.currentFrameCount += 1
            if self.currentFrameCount >= 184 {
                self.currentFrameCount %= 183
            }
            if let line = self.line {
                line.removeFromParent()
            }
            let cgPointList: [[CGPoint]] = self.realStageList.map({return $0.img.map({return CGPoint(x: CGFloat($0["x"] as! Int) * CGFloat(3.38) - CGFloat(self.size.width / 2), y: self.size.height - CGFloat($0["y"] as! Int) * CGFloat(3.38) - CGFloat(self.size.height / 2))})})
            
            self.createLine(with: cgPointList)
        })
    }
    
    private func createLine(with list: [[CGPoint]]) {
        //reverse image
        var tempCgList: [CGPoint] = list[(list.count - currentFrameCount) % list.count]
        
        line = SKShapeNode(points: &tempCgList, count: tempCgList.count)
        line?.physicsBody?.categoryBitMask = groundCategory
        line?.physicsBody?.contactTestBitMask = bikeManCategory
        line?.physicsBody?.collisionBitMask = bikeManCategory
        if let line = line {
            let path = CGMutablePath()
            path.addLines(between: tempCgList)
            path.closeSubpath()
            line.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            line.physicsBody?.categoryBitMask = self.groundCategory
            line.physicsBody?.contactTestBitMask = self.bikeManCategory
            line.physicsBody?.collisionBitMask = self.bikeManCategory
            line.physicsBody?.affectedByGravity = false
            line.physicsBody?.isDynamic = false
            line.physicsBody?.pinned = true
            line.zPosition = 1
            line.strokeColor = UIColor.red
            line.lineWidth = 10
            self.addChild(line)
        }
    }
    
    private func setupNodesInGameScene() {
        bikeMan = childNode(withName: "bikeMan") as? SKSpriteNode
        bikeMan?.physicsBody?.categoryBitMask = bikeManCategory
        bikeMan?.physicsBody?.contactTestBitMask = groundCategory
        bikeMan?.physicsBody?.collisionBitMask = groundCategory

        bikeMan?.zPosition = 1
        defaultGround = childNode(withName: "defaultGround") as? SKSpriteNode
        defaultGround?.zPosition = 1
        
        ceil = childNode(withName: "ceil") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    func countdown(count: Int) {
        countdownLabel = childNode(withName: "countdownLabel") as? SKLabelNode
        if let countdownLabel = countdownLabel {
            countdownLabel.horizontalAlignmentMode = .center
            countdownLabel.verticalAlignmentMode = .baseline
            countdownLabel.fontColor = .white
            countdownLabel.zPosition = 100
            countdownLabel.text = "\(count)"
        }
        countdownLabel?.isHidden = false
        countdownLabel?.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
 
        let counterDecrement = SKAction.sequence([SKAction.wait(forDuration: 1),
                                                  SKAction.run(countdownAction)])
        
        run(SKAction.sequence([SKAction.repeat(counterDecrement, count: 3),
                                     SKAction.run(endCountdown)]))
    }
    
    func countdownPulse() {
        countdownLabel?.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
    }
    
    func countdownAction() {
        count -= 1
        countdownLabel?.text = "\(count)"
        countdownLabel?.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
    }

    func endCountdown() {
        countdownLabel?.removeFromParent()
        if !isGameStarted {
            isGameStarted = true
            isAnimating = true
            startGame()
            return
        }
    }
    
    private func createMovieBG() {
        movieBG = SKSpriteNode(imageNamed: "image_1")
        if let movieBG = movieBG {
            movieBG.position = CGPoint(x: 360 / 2 * 3.38 - size.width / 2, y: 720 / 2 * 3.38 - size.height / 2)
            movieBG.size.height *= 3.38
            movieBG.size.width  *= 3.38
            addChild(movieBG)
        }
    }
    
    private func animateMovie() {
        var frames = [SKTexture]()
        
        for i in 1...183 {
            let index = 184 - i
            let frame = SKTexture.init(imageNamed: "image_\(index)")
            frames.append(frame)
        }
        if let movieBG = movieBG {
            movieBG.removeFromParent()
            movieBG.position = CGPoint(x: 360 / 2 * 3.38  - size.width / 2, y: 720 / 2 * 3.38 - size.height / 2)
            let animation = SKAction.animate(with: frames, timePerFrame: 0.03)
            movieBG.run(SKAction.repeatForever(animation))
            addChild(movieBG)
        }
    }
    
    private func startAnimation() {
        defaultGround?.removeFromParent()
        
        let moveLine = SKAction.moveBy(x: -1200 * magnification + size.width, y: 0, duration: TimeInterval(1200 * magnification) / scrollSpeed)
        line?.run(moveLine)
        
        if let background = background {
            let moveBackground = SKAction.moveBy(x: -background.size.width + size.width, y: 0, duration: TimeInterval(background.size.width) / scrollSpeed)
            background.run(moveBackground)
        }
        createRealTimeLine()
        animateMovie()
    }
    
    private func resetGame() {
        NotificationCenter.default.post(name: .resetGameNotification, object: nil)
    }
    
    private func startGame() {
        bikeMan?.physicsBody?.pinned = false
        startAnimation()
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
        bikeMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 50_000))
    }
    
    override func update(_ currentTime: TimeInterval) {
        let gap: CGFloat = 100.0
        if let bikeMan = bikeMan {
            if isAnimating && bikeMan.position.x < -size.width / 4 {
                bikeMan.position.x += 5
            }
            
            if isAnimating && bikeMan.position.x > -size.width / 4 {
                bikeMan.position.x -= 5
            }
            
            if isAnimating && bikeMan.position.x <= -size.width / 2 - gap || bikeMan.position.y <= -size.height / 2 - gap {
                gameOver()
            }
            
            if !isAnimating && bikeMan.position.x >= size.width / 2 + 50 {
                scene?.isPaused = true
            }
            
            if isGameStarted && !isAnimating {
                bikeMan.position.x += 2
                bikeMan.position.y += 20
            }
        }
        
        if let background = background {
            if background.position.x <= size.width / 2 - background.size.width / 2 + 1 {
                isAnimating = false
                gameClear()
            }
        }
    }
}


extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == bikeManCategory {
            print("contact!")
        }
        
        if contact.bodyB.categoryBitMask == bikeManCategory {
            print("contact!")
        }
    }
}
