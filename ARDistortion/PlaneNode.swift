//
//  PlaneNode.swift
//  ARDistortion
//
//  Created by ミズキ on 2022/08/12.
//

import ARKit
import SceneKit

class PlaneNode: NSObject {
    
    public let contentNode: SCNNode
    private let geometryNode: SCNNode
    private let vertexEffectMaterial: SCNMaterial
    private let sceneView: ARSCNView
    private let viewportSize: CGSize
    private var time: Float = 0.0
    private let PLANE_SCALE = Float(0.75)
    private let PLANE_SEGS = 60
    
    init(sceneView: ARSCNView,
         viewportSize: CGSize) {
        self.sceneView = sceneView
        self.viewportSize = viewportSize
        self.contentNode = SCNNode()
        
        let plane = SCNPlane(width: 1.0,
                             height: 1.0)
        //
        plane.widthSegmentCount = PLANE_SEGS
        plane.heightSegmentCount = PLANE_SEGS
        
        self.geometryNode = SCNNode(geometry: plane)
        self.geometryNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        self.geometryNode.scale = SCNVector3(PLANE_SCALE, PLANE_SCALE, PLANE_SCALE)
        
        // Nodeを入れる。
        self.contentNode.addChildNode(geometryNode)
        
        // Material
        vertexEffectMaterial = PlaneNode.createMaterial(vertexFunction: "geometryEffectVertextShader",
                                                        fragmentFunctionName: "geometryEffectFragmentShader")
        vertexEffectMaterial.setValue(SCNMaterialProperty(contents: sceneView.scene.background.contents!),
                                      forKey: "diffuseTexture")
        super.init()
        // geoMetryNodeのMaterialにシェーダーで作ったMaterialをセットする
        self.geometryNode.geometry?.firstMaterial = vertexEffectMaterial
    }
    
    func update(time: TimeInterval, timeDelta: Float)
    {
        // 時間timeDeltaに足す
        self.time += timeDelta
        // 現在のARフレームを取り出す
        guard let frame = sceneView.session.currentFrame else { return }
        // ARFrameから縦画面設定で与えられたviewPortSize(カメラ画像をレンダリングするためのビューサイズ）
        let affineTransform = frame.displayTransform(for: .portrait,
                                                     viewportSize: viewportSize)
        // アフィン変換から44の行列を作成
        let transform = SCNMatrix4(affineTransform)
      //ジオメトリーのーどの最初を取り出して
        let material = geometryNode.geometry!.firstMaterial!
        // Invert->先ほど作った逆行列を返す
        // それをdisplayTra
        material.setValue(SCNMatrix4Invert(transform),
                          forKey: "u_displayTransform")
        material.setValue(NSNumber(value: self.time),
                          forKey: "u_time")
        
    }
    private static func createMaterial(vertexFunction: String, fragmentFunctionName: String) -> SCNMaterial {
        let program = SCNProgram()
        // Shaderを追加したMaterialを設定。
        program.vertexFunctionName = vertexFunction
        program.fragmentFunctionName = fragmentFunctionName
        let material = SCNMaterial()
        material.program = program
        return material
    }
}

extension SCNMatrix4 {
    // CGAffineTransformから4,4の行列を作成する。
    init(_ affineTransform: CGAffineTransform) {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}
