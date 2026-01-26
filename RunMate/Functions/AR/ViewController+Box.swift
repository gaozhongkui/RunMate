//
//  ViewController.swift
//  ARKitTest
//
//  Created by gaozhongkui on 2026/1/14.
//

import ARKit
import SceneKit
import UIKit

class ViewControllerBox: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)

        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // 点击屏幕放置盒子
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)

        var position: SCNVector3 = .init()

        // iOS 14+ 使用 raycastQuery
        if let query = sceneView.raycastQuery(from: location,
                                              allowing: .existingPlaneGeometry,
                                              alignment: .horizontal)
        {
            let results = sceneView.session.raycast(query)
            if let firstResult = results.first {
                let t = firstResult.worldTransform
                position = SCNVector3(t.columns.3.x, t.columns.3.y + 0.025, t.columns.3.z)
            } else {
                // 没有平面：尝试 feature point
                if let featureQuery = sceneView.raycastQuery(from: location,
                                                             allowing: .estimatedPlane,
                                                             alignment: .any),
                    let featureResult = sceneView.session.raycast(featureQuery).first
                {
                    let t = featureResult.worldTransform
                    position = SCNVector3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
                } else {
                    // 如果都没有，放在摄像机前 0.5 米
                    let cameraTransform = sceneView.session.currentFrame?.camera.transform ?? matrix_identity_float4x4
                    position = SCNVector3(cameraTransform.columns.3.x,
                                          cameraTransform.columns.3.y,
                                          cameraTransform.columns.3.z - 0.5)
                }
            }
        }

        // 创建立方体
        let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue
        box.materials = [material]

        let node = SCNNode(geometry: box)
        node.position = position
        sceneView.scene.rootNode.addChildNode(node)
    }

    // 平面可视化
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // iOS 16+ 通过 vertices 计算平面大小
        let geometry = planeAnchor.geometry
        let vertices = geometry.vertices

        let minX = vertices.map { $0.x }.min() ?? 0
        let maxX = vertices.map { $0.x }.max() ?? 0
        let minZ = vertices.map { $0.z }.min() ?? 0
        let maxZ = vertices.map { $0.z }.max() ?? 0

        let width = CGFloat(maxX - minX)
        let length = CGFloat(maxZ - minZ)

        let plane = SCNPlane(width: width, height: length)
        plane.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.3)

        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
    }
}
