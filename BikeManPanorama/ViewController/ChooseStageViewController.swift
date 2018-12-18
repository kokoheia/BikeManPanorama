//
//  ChooseStageViewController.swift
//  BikeManPanorama
//
//  Created by Kohei Arai on 2018/12/15.
//  Copyright © 2018年 Kohei Arai. All rights reserved.
//

import UIKit

final class ChooseStageViewController: UIViewController {
    
    private var stages = [Stage]()
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        makeStageMock()
    }
    
    private func makeStageMock() {
        let akibaKanda = Stage(name: "秋葉原→神田", image: #imageLiteral(resourceName: "fuji"))
        let meguroGotanda = Stage(name: "目黒→五反田", image: #imageLiteral(resourceName: "free"))
        let tamachiShinagawa = Stage(name: "田町→品川", image: #imageLiteral(resourceName: "image_84"))
        stages = [akibaKanda, meguroGotanda, tamachiShinagawa]
    }
}


extension ChooseStageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stageCell", for: indexPath) as! StageCell
        cell.layer.cornerRadius = 14
        cell.layer.masksToBounds = true
        let stage = stages[indexPath.item]
        cell.imageView.image = stage.image
        cell.label.text = stage.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameViewController") as? GameViewController {
            viewController.name = stages[indexPath.item].name
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let testSection = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath)
        return testSection
    }
}
