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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            addNotification()
        }
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(restartGame), name: .resetGameNotification, object: nil)
    }
    
    @objc private func restartGame() {
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") {
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
