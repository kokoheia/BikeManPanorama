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
    
    private let bikeManCategory: UInt32 = 0x1 << 1
    private let groundCategory: UInt32 = 0x1 << 2
    
    override func didMove(to view: SKView) {
//        createBackground()
        setupNodesInGameScene()
        createPointListFromCSV()
//        createMovie()
//        createLine()
//        createGroundListMock()
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
        var currentFrameCount = 0
        
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
            
            var tempCgList: [CGPoint] = cgPointList[(cgPointList.count - currentFrameCount) % cgPointList.count]
            
            line = SKShapeNode(points: &tempCgList, count: tempCgList.count)
            line?.physicsBody?.categoryBitMask = groundCategory
            line?.physicsBody?.contactTestBitMask = bikeManCategory
            line?.physicsBody?.collisionBitMask = bikeManCategory
            //        let lineWidth = lineXMax - lineXMin
            //        let lineHeight = lineYMax - lineYMin
            //        let lineWidth: CGFloat = 1200
            //        let lineHeight: CGFloat = 800
            //        line.position = CGPoint(x: lineWidth / 2, y: lineHeight / 2)
            //        let lineSize =
            if let line = line {
                let path = CGMutablePath()
                path.addLines(between: tempCgList)
                path.closeSubpath()
                line.physicsBody = SKPhysicsBody(edgeChainFrom: path)
                line.physicsBody?.affectedByGravity = false
                line.physicsBody?.isDynamic = false
                line.physicsBody?.pinned = true
                line.zPosition = 1
                line.strokeColor = UIColor.white
                self.addChild(line)
            }
        } catch let parsingError {
            print("Error", parsingError)
        }
        
        
        let movieTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true, block: { (timer) in
            currentFrameCount += 1
            if currentFrameCount >= 184 {
                currentFrameCount %= 183
            }
            if let line = self.line {
                line.removeFromParent()
            }
//            shortPointList = shortPointList.map({ (point) -> CGPoint in
//                return CGPoint(x: point.x + 1, y: point.y + 1)
//            })
            let cgPointList: [[CGPoint]] = self.realStageList.map({return $0.img.map({return CGPoint(x: CGFloat($0["x"] as! Int) * CGFloat(3.38) - CGFloat(self.size.width / 2), y: self.size.height - CGFloat($0["y"] as! Int) * CGFloat(3.38) - CGFloat(self.size.height / 2))})})
            
            var tempCgList: [CGPoint] = cgPointList[(cgPointList.count - currentFrameCount) % cgPointList.count]
            self.line = SKShapeNode(points: &tempCgList, count: tempCgList.count)
            let path = CGMutablePath()
            path.addLines(between: tempCgList)
            path.closeSubpath()
            self.line?.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            self.line?.physicsBody?.categoryBitMask = self.groundCategory
            self.line?.physicsBody?.contactTestBitMask = self.bikeManCategory
            self.line?.physicsBody?.collisionBitMask = self.bikeManCategory
            self.line?.physicsBody?.affectedByGravity = false
            self.line?.physicsBody?.isDynamic = false
            self.line?.physicsBody?.pinned = true
            self.line?.lineWidth = 10
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
//                print(pointList)
//                print(pointList.count)
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    private func setupNodesInGameScene() {
        bikeMan = childNode(withName: "bikeMan") as? SKSpriteNode
        bikeMan?.physicsBody?.categoryBitMask = bikeManCategory
        bikeMan?.physicsBody?.contactTestBitMask = groundCategory
        bikeMan?.zPosition = 1
        defaultGround = childNode(withName: "defaultGround") as? SKSpriteNode
        defaultGround?.zPosition = 1
        
        ceil = childNode(withName: "ceil") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let countdownLabel = self.countdownLabel {
//            countdownLabel.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//        if !isGameStarted {
//            isGameStarted = true
//            isAnimating = true
//            startGame()
//            return
//        }
//
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
//            countdownLabel.position = CGPoint(x: , y: size.height*(1/3))
            countdownLabel.fontColor = .white
//            countdownLabel.fontSize = size.height / 30
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
//            movieBG.size.height *= 3.38
//            movieBG.size.width  *= 3.38
//            let originalHeight: CGFloat = 720
//            let newHeight = frame.size.height
//            movieBG.size.height = size.height
//            magnification = newHeight / originalHeight
//            movieBG.size.width  = size.width * magnification
            let animation = SKAction.animate(with: frames, timePerFrame: 0.03)
            movieBG.run(SKAction.repeatForever(animation))
            addChild(movieBG)
        }
    }
    
    private func startAnimation() {
//        let moveDefaultGround = SKAction.moveBy(x: -defaultGround!.size.width, y: 0, duration: TimeInterval(defaultGround!.size.width) / scrollSpeed)
//        defaultGround?.run(moveDefaultGround)
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
