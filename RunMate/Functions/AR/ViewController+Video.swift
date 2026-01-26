//
//  ViewController.swift
//  ARKitTest
//
//  Created by gaozhongkui on 2026/1/14.
//

import UIKit
import RealityKit
import ARKit
import AVFoundation

class ViewControllerVideo: UIViewController {

    var arView: ARView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化 ARView
        arView = ARView(frame: self.view.bounds)
        self.view.addSubview(arView)

        // 显示特征点和世界原点辅助
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // AR 配置
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

    // 点击屏幕放置视频
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)

        // 使用 raycast 查询水平平面
        if let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal).first {
            let position = result.worldTransform.translation
            addVideoEntity(at: position)
        }
    }

    // MARK: - 添加 RealityKit 视频实体
    func addVideoEntity(at position: SIMD3<Float>) {
        guard let url = Bundle.main.url(forResource: "test", withExtension: "mp4") else {
            print("视频资源不存在")
            return
        }

        let player = AVPlayer(url: url)

        // 循环播放
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem,
                                               queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        // 创建视频材质
        let material = VideoMaterial(avPlayer: player)

        // 创建平面实体
        let mesh = MeshResource.generatePlane(width: 0.5, height: 0.3)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // 设置位置
        entity.position = position

        // 添加 Anchor
        let anchor = AnchorEntity(world: position)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)

        // 播放视频
        player.play()
    }
}

// MARK: - Helper 扩展
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        let t = columns.3
        return SIMD3<Float>(t.x, t.y, t.z)
    }
}
