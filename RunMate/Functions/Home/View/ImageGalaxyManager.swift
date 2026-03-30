import SwiftUI
import Combine

private struct ImageParticle: Identifiable {
    let id = UUID()
    let imageName: String // 存储图片在 Assets 中的名称
    let polarTheta: Double
    let polarPhi: Double
    let radius: Double
}

// MARK: - 图片星系 Canvas 视图
struct ImageGalaxyCanvas: View {
    let namespace: Namespace.ID
    
    // 粒子配置
    private let particleCount = 150 // 减少粒子数量
    private let imagePool = ["ai_test"] // 简化，只用一个图片
    @State private var particles: [ImageParticle] = []
    
    // 状态控制
    @State private var dragOffset = CGSize.zero
    @State private var animationTime: Double = 0
    @State private var isScattered: Bool = false // 新增：控制粒子是否分散
    @State private var selectedParticle: ImageParticle? = nil // 新增：选中的粒子

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. 背景深空渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.04, green: 0.06, blue: 0.15), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 2. 简化版本：使用 ForEach 显示图片
                ForEach(particles) { item in
                    let rotationY = animationTime * 0.12 + Double(dragOffset.width / 120)
                    let rotationX = animationTime * 0.08 + Double(dragOffset.height / 120)
                    
                    // 根据分散状态计算位置
                    let pos = isScattered ?
                        scatteredPoint(for: item, in: proxy.size) :
                        sphericalPoint(theta: item.polarTheta, phi: item.polarPhi, radius: 150)
                    let rotated = rotate(point: pos, x: rotationX, y: rotationY)
                    let projection = project(point: rotated, in: proxy.size)
                    
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 35 * projection.scale, height: 35 * projection.scale)
                        .position(x: projection.x, y: projection.y)
                        .opacity(0.2 + projection.scale * 0.8)
                        .onTapGesture {
                            selectedParticle = item
                        }
                }
                
                // 3. UI 叠加层
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("IMAGE GALAXY")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.linearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                            Text("Double-tap to scatter").font(.caption).foregroundColor(.white.opacity(0.6))
                        }
                    }.padding(30)
                    Spacer()
                }
                
                // 全屏图片查看器
                if let particle = selectedParticle {
                    ZStack {
                        Color.black.opacity(0.8).ignoresSafeArea()
                        
                        // 关闭按钮 - 放在右上角
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedParticle = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding()
                                }
                                .padding(.top, proxy.safeAreaInsets.top + 10 + 16) // 额外向下 16pt
                                .padding(.trailing, 10)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        
                        // 图片内容
                        Image(particle.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: proxy.size.width * 0.8, maxHeight: proxy.size.height * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 20)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { dragOffset = $0.translation }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { dragOffset = .zero }
                    }
            )
            .gesture(
                TapGesture(count: 2) // 双击手势
                    .onEnded {
                        withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                            isScattered.toggle()
                        }
                    }
            )
            .onReceive(Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()) { _ in
                animationTime = Date().timeIntervalSinceReferenceDate
            }
        }
        .onAppear(perform: setupParticles)
    }

    // MARK: - 辅助计算函数 (保持不变)
    
    private func setupParticles() {
        guard particles.isEmpty else { return }
        particles = (0..<particleCount).map { index in
            let phi = acos(1 - 2 * Double(index) / Double(particleCount))
            let theta = Double(index) * .pi * (3 - sqrt(5))
            return ImageParticle(
                imageName: imagePool.randomElement()!, // 随机分配图片
                polarTheta: theta,
                polarPhi: phi,
                radius: 150
            )
        }
    }

    private func sphericalPoint(theta: Double, phi: Double, radius: Double) -> SIMD3<Double> {
        let x = radius * sin(phi) * cos(theta)
        let y = radius * sin(phi) * sin(theta)
        let z = radius * cos(phi)
        return SIMD3(x, y, z)
    }

    private func rotate(point: SIMD3<Double>, x: Double, y: Double) -> SIMD3<Double> {
        let sinY = sin(y), cosY = cos(y)
        let sinX = sin(x), cosX = cos(x)
        var p = SIMD3(point.x * cosY + point.z * sinY, point.y, -point.x * sinY + point.z * cosY)
        p = SIMD3(p.x, p.y * cosX - p.z * sinX, p.y * sinX + p.z * cosX)
        return p
    }

    private func project(point: SIMD3<Double>, in size: CGSize) -> (x: CGFloat, y: CGFloat, scale: CGFloat) {
        let fov: Double = 650
        let perspective = fov / (fov + point.z + 100)
        let x = CGFloat(point.x * perspective) + size.width / 2
        let y = CGFloat(point.y * perspective) + size.height / 2
        let scale = CGFloat(perspective)
        return (x, y, scale)
    }

    private func scatteredPoint(for particle: ImageParticle, in size: CGSize) -> SIMD3<Double> {
        // 将粒子分散到屏幕的随机位置
        let screenWidth = Double(size.width)
        let screenHeight = Double(size.height)
        
        // 使用粒子的ID作为种子生成稳定的随机位置
        let seed = particle.id.hashValue
        let randomX = Double(seed % 1000) / 1000.0 * screenWidth - screenWidth / 2
        let randomY = Double((seed / 1000) % 1000) / 1000.0 * screenHeight - screenHeight / 2
        let randomZ = Double((seed / 1000000) % 1000) / 1000.0 * 200 - 100 // Z轴随机分布
        
        return SIMD3(randomX, randomY, randomZ)
    }
}
