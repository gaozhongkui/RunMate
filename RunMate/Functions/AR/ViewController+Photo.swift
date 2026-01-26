//
//  ViewController.swift
//  ARKitTest
//
//  Created by gaozhongkui on 2026/1/14.
//
import ARKit
import Combine
import Photos
import RealityKit
import UIKit

class ViewControllerPhoto: UIViewController {
    
    var arView: ARView!
    var sphereAnchor: AnchorEntity!
    let sphereRadius: Float = 2.0 // 照片球的半径
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARView()
        setupGesture()
        
        // 开始异步任务加载图片并构建 3D 场景
        Task {
            // 建议 limit 设置为 12-30 张，球形效果会非常漂亮
            let photoList = await PhotosUtils.fetchPhotos(limit: 20)
            
            await MainActor.run {
                self.buildPhotoSphere(images: photoList)
            }
        }
    }
    
    // MARK: - 1. 初始化 View
    func setupARView() {
        // 使用 .nonAR 模式，不需要开启摄像头
        arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.backgroundColor = .black // 设置背景为黑色，更有空间感
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 添加非 AR 摄像机
        let camera = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)
        
        // 相机后移，保证能看到整个球体
        camera.position = [0, 0, 6]
    }
    
    // MARK: - 2. 构建照片球
    func buildPhotoSphere(images: [UIImage]) {
        sphereAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(sphereAnchor)
        
        let total = images.count
        
        for (index, image) in images.enumerated() {
            // 创建单张照片实体
            let entity = self.createPlaneEntity(from: image)
            
            // 计算球面坐标 (Fibonacci Sphere 算法实现均匀分布)
            let position = calculateSphericalPosition(index: index, total: total)
            entity.position = position
            
            // 让照片面向中心点 (0,0,0)，这样从外面看每张图都是正的
            // 如果想从内部看，可以调整 lookAt 的逻辑
            entity.look(at: .zero, from: position, relativeTo: nil)
            
            sphereAnchor.addChild(entity)
        }
    }
    
    func createPlaneEntity(from image: UIImage) -> ModelEntity {
        // 创建一个小圆角的平面
        let mesh = MeshResource.generatePlane(width: 0.8, height: 0.8, cornerRadius: 0.05)
        
        var material = UnlitMaterial()
        if let cgImage = image.cgImage,
           let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) {
            material.color = .init(tint: .white.withAlphaComponent(0.95), texture: .init(texture))
        }
        
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    // MARK: - 3. 数学计算：球面均匀分布
    func calculateSphericalPosition(index: Int, total: Int) -> SIMD3<Float> {
        let n = Float(total)
        let i = Float(index)
        
        let y = 1 - (i / (n - 1)) * 2 // y 范围从 1 到 -1
        let radiusAtY = sqrt(1 - y * y) // 在该高度下的圆半径
        
        let goldenAngle = Float.pi * (3 - sqrt(5)) // 黄金角度
        let theta = goldenAngle * i // 经度旋转
        
        let x = cos(theta) * radiusAtY
        let z = sin(theta) * radiusAtY
        
        return SIMD3<Float>(x, y, z) * sphereRadius
    }
    
    // MARK: - 4. 交互：滑动旋转球体
    func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        arView.addGestureRecognizer(pan)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: arView)
        
        // 将滑动手势转化为旋转弧度
        let sensitivity: Float = 0.005
        let xRotation = Float(translation.x) * sensitivity
        let yRotation = Float(translation.y) * sensitivity
        
        if let anchor = sphereAnchor {
            // 绕 Y 轴（水平转动）
            let rotationY = simd_quatf(angle: xRotation, axis: [0, 1, 0])
            // 绕 X 轴（垂直转动）
            let rotationX = simd_quatf(angle: yRotation, axis: [1, 0, 0])
            
            anchor.orientation = rotationY * rotationX * anchor.orientation
        }
        
        gesture.setTranslation(.zero, in: arView)
    }
}
