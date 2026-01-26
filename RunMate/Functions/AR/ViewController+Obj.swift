//
//  ViewController.swift
//  ARKitTest
//
//  Created by gaozhongkui on 2026/1/14.
//
import UIKit
import RealityKit
import ARKit
import Combine

class ViewControllerObj: UIViewController {

    var arView: ARView!
    var modelEntity: ModelEntity!
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1️⃣ 初始化 ARView
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)

        // 2️⃣ 配置 ARWorldTracking
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal] // 检测水平面
        arView.session.run(config)

        // 3️⃣ 加载模型
        loadModel(named: "model") // 模型名，不带后缀（toy_robot.usdz 或 toy_robot.glb）
        
        // 4️⃣ 添加点击手势触发动画
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    func loadModel(named name: String) {
        // 异步加载模型
        cancellable = ModelEntity.loadModelAsync(named: name)
            .sink(receiveCompletion: { loadCompletion in
                if case let .failure(error) = loadCompletion {
                    print("模型加载失败: \(error)")
                }
            }, receiveValue: { model in
                self.modelEntity = model
                self.modelEntity.generateCollisionShapes(recursive: true)

                // 创建 Anchor 并添加模型
                let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
                anchor.addChild(self.modelEntity)
                self.arView.scene.addAnchor(anchor)

                // 添加手势交互
                self.arView.installGestures([.translation, .rotation, .scale], for: self.modelEntity)
                
                self.playModelAnimation()

            })
    }
    
    
    func playModelAnimation() {
        guard let model = modelEntity else { return }

        // 打印模型中可用动画
        let animations = model.availableAnimations
        print("模型动画列表: \(animations)")

        // 播放第一个动画
        if let firstAnimation = animations.first {
            model.playAnimation(firstAnimation.repeat(duration: .infinity), transitionDuration: 0.3, startsPaused: false)
        }
    }

    // 点击事件
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)

        // 检测用户是否点击到模型
        if let entity = arView.entity(at: tapLocation), entity == modelEntity {
            animateModel()
        }
    }

    // 动画函数：旋转 + 缩放 + 可移动
    func animateModel() {
        guard let model = modelEntity else { return }

        var transform = model.transform

        // 旋转 180° Y 轴
        transform.rotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))

        // 缩放 1.5 倍
        transform.scale = SIMD3<Float>(1.5, 1.5, 1.5)

        // 稍微抬高
        transform.translation = SIMD3<Float>(0, 0.1, 0)

        // 执行动画，持续 1 秒
        model.move(to: transform, relativeTo: model, duration: 1.0)
    }
}
