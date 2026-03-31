//
//  USDZPlayerView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/3/30.
//

import SwiftUI
import RealityKit
import ARKit
import UIKit

// MARK: - Player Reference (bridge between SwiftUI and UIKit)

class USDZRealityViewRef {
    weak var coordinator: USDZRealityViewRepresentable.Coordinator?

    func play(animationName: String?) {
        coordinator?.play(animationName: animationName)
    }

    func pause() {
        coordinator?.pause()
    }

    func stop() {
        coordinator?.stop()
    }
}

// MARK: - UIViewRepresentable

struct USDZRealityViewRepresentable: UIViewRepresentable {
    let usdzFileName: String
    @Binding var isPlaying: Bool
    @Binding var animationNames: [String]
    @Binding var selectedAnimation: String?
    @Binding var playerRef: USDZRealityViewRef?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(.black)

        let coordinator = context.coordinator
        coordinator.arView = arView

        let ref = USDZRealityViewRef()
        ref.coordinator = coordinator

        if let url = Bundle.main.url(forResource: usdzFileName, withExtension: "usdz") {
            coordinator.loadModel(url: url) { names in
                DispatchQueue.main.async {
                    self.animationNames = names
                    self.selectedAnimation = names.first
                    self.playerRef = ref
                    if let first = names.first {
                        coordinator.play(animationName: first)
                        self.isPlaying = true
                    }
                }
            }
        }

        let rotationGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(rotationGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject {
        weak var arView: ARView?
        var modelEntity: Entity?
        var cameraEntity: PerspectiveCamera?
        var animationPlaybackControllers: [String: AnimationPlaybackController] = [:]
        var currentController: AnimationPlaybackController?

        // Gesture state
        var lastPanTranslation: CGPoint = .zero
        var currentRotationX: Float = 0
        var currentRotationY: Float = 0
        var currentScale: Float = 1.0

        func loadModel(url: URL, completion: @escaping ([String]) -> Void) {
            guard let arView = arView else { return }

            do {
                let entity = try Entity.load(contentsOf: url)

                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(entity)
                arView.scene.addAnchor(anchor)

                // 居中模型
                let bounds = entity.visualBounds(relativeTo: nil)
                let center = bounds.center
                entity.position = -center

                // 设置透视相机
                let size = bounds.extents
                let maxDim = max(size.x, max(size.y, size.z))
                let distance = maxDim * 2.5

                let camera = PerspectiveCamera()
                camera.camera.fieldOfViewInDegrees = 60
                let cameraAnchor = AnchorEntity(world: [0, maxDim * 0.3, distance])
                cameraAnchor.addChild(camera)
                arView.scene.addAnchor(cameraAnchor)
                self.cameraEntity = camera

                self.modelEntity = entity

                // 收集动画名称并缓存控制器
                var names: [String] = []
                for (index, anim) in entity.availableAnimations.enumerated() {
                    let rawName = anim.name ?? ""
                    let key = rawName.isEmpty ? "Animation \(index + 1)" : rawName
                    names.append(key)
                    let controller = entity.playAnimation(anim.repeat(), transitionDuration: 0.3, startsPaused: true)
                    animationPlaybackControllers[key] = controller
                }

                completion(names)

            } catch {
                print("Failed to load USDZ: \(error)")
                completion([])
            }
        }

        func play(animationName: String?) {
            guard let entity = modelEntity else { return }

            // 暂停当前
            currentController?.pause()

            if let name = animationName, let controller = animationPlaybackControllers[name] {
                controller.resume()
                currentController = controller
            } else if let first = entity.availableAnimations.first {
                let controller = entity.playAnimation(first.repeat(), transitionDuration: 0.3)
                currentController = controller
            }
        }

        func pause() {
            currentController?.pause()
        }

        func stop() {
            currentController?.stop()
            currentController = nil
        }

        // MARK: - Gestures

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let entity = modelEntity else { return }

            let translation = gesture.translation(in: gesture.view)
            let deltaX = Float(translation.x - lastPanTranslation.x) * 0.005
            let deltaY = Float(translation.y - lastPanTranslation.y) * 0.005

            currentRotationY += deltaX
            currentRotationX += deltaY
            currentRotationX = max(-Float.pi / 2, min(Float.pi / 2, currentRotationX))

            let rotX = simd_quatf(angle: currentRotationX, axis: [1, 0, 0])
            let rotY = simd_quatf(angle: currentRotationY, axis: [0, 1, 0])
            entity.orientation = rotY * rotX

            lastPanTranslation = translation

            if gesture.state == .ended || gesture.state == .cancelled {
                lastPanTranslation = .zero
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let entity = modelEntity else { return }

            if gesture.state == .changed {
                currentScale *= Float(gesture.scale)
                currentScale = max(0.1, min(currentScale, 5.0))
                entity.scale = [currentScale, currentScale, currentScale]
                gesture.scale = 1.0
            }
        }
    }
}

// MARK: - SwiftUI View

struct USDZPlayerView: View {
    let usdzFileName: String

    @State private var isPlaying: Bool = false
    @State private var animationNames: [String] = []
    @State private var selectedAnimation: String? = nil
    @State private var playerRef: USDZRealityViewRef? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            USDZRealityViewRepresentable(
                usdzFileName: usdzFileName,
                isPlaying: $isPlaying,
                animationNames: $animationNames,
                selectedAnimation: $selectedAnimation,
                playerRef: $playerRef
            )

            VStack {
                Spacer()

                if !animationNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(animationNames, id: \.self) { name in
                                Button(action: {
                                    selectedAnimation = name
                                    playerRef?.play(animationName: name)
                                    isPlaying = true
                                }) {
                                    Text(name)
                                        .font(.caption)
                                        .foregroundColor(selectedAnimation == name ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedAnimation == name
                                            ? Color.white
                                            : Color.white.opacity(0.2)
                                        )
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }

                HStack(spacing: 40) {
                    Button(action: {
                        isPlaying = false
                        playerRef?.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        isPlaying.toggle()
                        if isPlaying {
                            playerRef?.play(animationName: selectedAnimation)
                        } else {
                            playerRef?.pause()
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationTitle(usdzFileName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    USDZPlayerView(usdzFileName: "Strut Walking")
}
