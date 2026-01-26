//
//  ARViewContainer.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        // 初始化 ARView
        let arView = ARView(frame: .zero)
        
        // 配置 AR 会话（例如：水平面检测）
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        
        // 添加一个简单的 3D 方块作为示例
        let mesh = MeshResource.generateBox(size: 0.1) // 10厘米的方块
        let material = SimpleMaterial(color: .systemBlue, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // 创建锚点（将物体固定在现实世界的某个位置）
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(model)
        
        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
