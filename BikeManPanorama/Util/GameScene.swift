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
    
    //parameters
    private var groundList = [(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)]()
    private var pointList = [CGPoint]()
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
    
    override func didMove(to view: SKView) {
//        createBackground()
        setupNodesInGameScene()
        createPointListFromCSV()
        createMovie()
//        createLine()
//        createGroundListMock()
        var count = 0
        var shortPointList = [CGPoint]()
        shortPointList = Array(pointList[0..<200])
        if let line = line {
            let path = CGMutablePath()
            shortPointList = Array(pointList[0..<200])
            path.addLines(between: shortPointList)
            path.closeSubpath()
            line.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            line.physicsBody?.affectedByGravity = false
            line.physicsBody?.isDynamic = false
            line.physicsBody?.pinned = true
            line.lineWidth = 100
            line.zPosition = 1
            line.strokeColor = UIColor.red
            self.addChild(line)
        }
        let movieTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true, block: { (timer) in
            if let line = self.line {
                line.removeFromParent()
            }
            shortPointList = shortPointList.map({ (point) -> CGPoint in
                return CGPoint(x: point.x + 1, y: point.y + 1)
            })
            self.line = SKShapeNode(points: &shortPointList, count: shortPointList.count)
            self.line?.lineWidth = 100
            self.line?.zPosition = 1
            self.line?.strokeColor = UIColor.red
            self.addChild(self.line!)
        })
    }
    
    private func createPointListFromCSV() {
        if let csvPath = Bundle.main.path(forResource: "data", ofType: "csv") {
            do {
                let csvStr = try String(contentsOfFile:csvPath, encoding:String.Encoding.utf8)
                let csvArr = csvStr.components(separatedBy: .newlines)
                pointList = csvArr.map { (coord) -> CGPoint in
                    let arr = coord.components(separatedBy: ",")
                    if csvArr.firstIndex(of: coord) == 0 || csvArr.firstIndex(of: coord) == csvArr.count - 1 {
                        return CGPoint(x: 0, y: 0)
                    } else {
//                        if CGFloat(Int(arr[3])!) <= lineXMin {
//                            lineXMin = CGFloat(Int(arr[3])!)
//                        }
//
//                        if CGFloat(Int(arr[3])!) >= lineXMax {
//                            lineXMax = CGFloat(Int(arr[3])!)
//                        }
//
//                        if CGFloat(Int(arr[4])!) <= lineYMin {
//                            lineYMin = CGFloat(Int(arr[4])!)
//                        }
//
//                        if CGFloat(Int(arr[4])!) >= lineYMax {
//                            lineYMax = CGFloat(Int(arr[4])!)
//                        }
                        
                        return CGPoint(x: CGFloat(Int(arr[3]) ?? 0) * magnification - size.width / 2, y: CGFloat((Int(arr[4]) ?? 0)) * magnification - size.height / 2)
                        
                    }
                }
                pointList = Array(pointList[1..<pointList.count-1])
                print(pointList)
                print(pointList.count)
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    private func setupNodesInGameScene() {
        bikeMan = childNode(withName: "bikeMan") as? SKSpriteNode
        bikeMan?.zPosition = 1
        defaultGround = childNode(withName: "defaultGround") as? SKSpriteNode
        defaultGround?.zPosition = 1
        
        ceil = childNode(withName: "ceil") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            isGameStarted = true
            isAnimating = true
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
    
    private func createMovie() {
        var frames = [SKTexture]()
        
        for i in 1...60 {
            let frame = SKTexture.init(imageNamed: "image_\(i)")
            frames.append(frame)
        }
        
        let node = SKSpriteNode(imageNamed: "image_1")
        node.position = CGPoint(x: 0, y: 0)
        node.size.height = size.height
        node.size.width  = size.width
        let animation = SKAction.animate(with: frames, timePerFrame: 0.03)
//        SKAction.animte
        node.run(SKAction.repeatForever(animation))
        
        addChild(node)
    }
    
    private func startAnimation() {
        let moveDefaultGround = SKAction.moveBy(x: -defaultGround!.size.width, y: 0, duration: TimeInterval(defaultGround!.size.width) / scrollSpeed)
        defaultGround?.run(moveDefaultGround)
        
        let moveLine = SKAction.moveBy(x: -1200 * magnification + size.width, y: 0, duration: TimeInterval(1200 * magnification) / scrollSpeed)
        line?.run(moveLine)
        
        if let background = background {
            let moveBackground = SKAction.moveBy(x: -background.size.width + size.width, y: 0, duration: TimeInterval(background.size.width) / scrollSpeed)
            background.run(moveBackground)
        }
    }
    
    private func resetGame() {
        NotificationCenter.default.post(name: .resetGameNotification, object: nil)
    }
    
    private func startGame() {
//        updateDefaultGround()
//        createGround()
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
//        scene?.isPaused = true
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
    
    private func createBackground() {
        background = SKSpriteNode(imageNamed: "fuji")
        if let background = background {
            let originalHeight = background.size.height
            let newHeight = frame.size.height
            magnification = newHeight / originalHeight
            background.size.height = newHeight
            background.size.width *= magnification
//
            background.position = CGPoint(x: background.size.width / 2 - size.width / 2, y:  background.size.height / 2 - size.height / 2)
            addChild(background)
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
    
    private func createLine() {
        line = SKShapeNode(points: &pointList, count: pointList.count)
//        let lineWidth = lineXMax - lineXMin
//        let lineHeight = lineYMax - lineYMin
//        let lineWidth: CGFloat = 1200
//        let lineHeight: CGFloat = 800
//        line.position = CGPoint(x: lineWidth / 2, y: lineHeight / 2)
//        let lineSize =
        if let line = line {
            let path = CGMutablePath()
            path.addLines(between: pointList)
            path.closeSubpath()
            line.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            line.physicsBody?.affectedByGravity = false
            line.physicsBody?.isDynamic = false
            line.physicsBody?.pinned = true
            line.zPosition = 1
            line.strokeColor = UIColor.white
            self.addChild(line)
        }
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
