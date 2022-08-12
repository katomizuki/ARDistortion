//
//  ViewController.swift
//  ARDistortion
//
//  Created by ミズキ on 2022/08/12.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    private var placedPlane: Bool = false
    private var planeNode: PlaneNode?
    private let configuration = ARWorldTrackingConfiguration()
    private var viewFrame: CGRect?
    private var lastUpdateTime: TimeInterval?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.bounds,
                              options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal])
        sceneView.delegate = self
        // ライトを作成するの自動でするかどうかを選択
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
        viewFrame = sceneView.bounds
        
        // 環境テクスチャを生成するかどうか
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal, .vertical]
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.session.run(configuration,
                              options: [.resetTracking, .removeExistingAnchors])
        
    }


}
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer,
                  nodeFor anchor: ARAnchor) -> SCNNode? {
        guard planeNode == nil else { return nil }
        if anchor is ARPlaneAnchor {
            planeNode = PlaneNode(sceneView: sceneView,
                                  viewportSize: viewFrame!.size)
            sceneView.scene.rootNode.addChildNode(planeNode!.contentNode)
        }
        return nil
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {
        // lastUpdateTimeがnilだったら0.03を入れる。そうではなかったら引き算
        let delta: Float = lastUpdateTime == nil ? 0.03 : Float(time - lastUpdateTime!)
        // updateした時間を更新
        lastUpdateTime = time

        // planeNodeがnilでなければ
        if planeNode != nil {
            // 歪み床のBool値
            let couldPlace = tryPlacePlaneInWorld(
                planeNode: planeNode!,
                screenLocation: CGPoint(x: viewFrame!.width / 2,
                                        y: viewFrame!.height / 2))
            // planeNodeを見せたいからfalseにする
            planeNode!.contentNode.isHidden = !couldPlace
        }
// updateする
        planeNode?.update(time: time, timeDelta: delta)
    }
    
    private func tryPlacePlaneInWorld(planeNode: PlaneNode,
                                      screenLocation: CGPoint) -> Bool {
        // 床を置けてればtrue
        if placedPlane {
            return true
        }
// スクリーンのロケーションから　レイキャストでPlaneを揺らす。
        guard let query = sceneView.raycastQuery(from: screenLocation,
                                                 allowing: .existingPlaneGeometry,
                                                 alignment: .any),
              let hitTestResult = sceneView.session.raycast(query).first
        else { return false }
// 見つかったら床を置くのでtrue
        placedPlane = true
        // ヒットしたワールド座標をコンテンツノードに入れてあげる
        planeNode.contentNode.simdWorldTransform = hitTestResult.worldTransform

        return true
    }
}

