//
//  GameViewController.swift
//  BikeManPanorama
//
//  Created by Kohei Arai on 2018/12/14.
//  Copyright © 2018年 Kohei Arai. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

final class GameViewController: UIViewController {
    
    var mode: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                scene.scaleMode = .aspectFill
                scene.mode = mode
                view.presentScene(scene)
            }
            view.ignoresSiblingOrder = true
            addNotification()
        }
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(restartGame), name: .resetGameNotification, object: nil)
    }
    
    @objc private func restartGame() {
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                scene.mode = mode
                scene.scaleMode = .aspectFill
                view.presentScene(scene)
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension Notification.Name {
    static let resetGameNotification = Notification.Name("resetNotification")
}
