import SwiftUI
import Photos
import UIKit
import Combine

// MARK: - Shape Mode
enum GalaxyShape: CaseIterable, Hashable {
    case sphere, heart, spiral, dna, scattered

    var displayName: String {
        switch self {
        case .sphere:    return "SPHERE"
        case .heart:     return "HEART"
        case .spiral:    return "SPIRAL"
        case .dna:       return "DNA"
        case .scattered: return "COSMOS"
        }
    }

    var icon: String {
        switch self {
        case .sphere:    return "circle.circle"
        case .heart:     return "heart.fill"
        case .spiral:    return "hurricane"
        case .dna:       return "staroflife"
        case .scattered: return "sparkles"
        }
    }

    func next() -> GalaxyShape {
        let all = GalaxyShape.allCases
        return all[((all.firstIndex(of: self) ?? 0) + 1) % all.count]
    }
}

// MARK: - Data Models
private struct ImageParticle: Identifiable {
    let id = UUID()
    let asset: PHAsset?
    let index: Int
}

private struct StarParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let twinkleOffset: Double
}

// MARK: - Heart Shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w / 2, y: h * 0.9))
        path.addCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.38),
            control1: CGPoint(x: w * 0.15, y: h * 0.9),
            control2: CGPoint(x: w * 0.0,  y: h * 0.62)
        )
        path.addArc(center: CGPoint(x: w * 0.3, y: h * 0.3), radius: w * 0.205,
                    startAngle: .degrees(195), endAngle: .degrees(0), clockwise: false)
        path.addArc(center: CGPoint(x: w * 0.7, y: h * 0.3), radius: w * 0.205,
                    startAngle: .degrees(180), endAngle: .degrees(-15), clockwise: false)
        path.addCurve(
            to: CGPoint(x: w / 2, y: h * 0.9),
            control1: CGPoint(x: w * 1.0,  y: h * 0.62),
            control2: CGPoint(x: w * 0.85, y: h * 0.9)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - AnyShape Type Erasure
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path
    init<S: Shape>(_ shape: S) { _path = { shape.path(in: $0) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

// MARK: - Image Galaxy Main View
struct ImageGalaxyCanvas: View {
    let namespace: Namespace.ID

    @State private var particles: [ImageParticle] = []
    @State private var images: [UUID: UIImage] = [:]
    @State private var stars: [StarParticle] = []

    @State private var dragOffset  = CGSize.zero
    @State private var animationTime: Double = 0
    @State private var currentShape: GalaxyShape = .sphere
    @State private var selectedParticle: ImageParticle? = nil
    @State private var lastInteractionTime: Double = 0
    @State private var isTransitioning = false

    private var isRingMode: Bool { particles.count > 0 && particles.count < 10 }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(proxy: proxy)
                nebulaLayer(proxy: proxy)

                ForEach(depthSortedParticles(in: proxy)) { item in
                    particleView(item: item, proxy: proxy)
                }

                overlayUI(proxy: proxy)

                if let particle = selectedParticle {
                    fullScreenViewer(particle: particle, proxy: proxy)
                }
            }
            .gesture(DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { dragOffset = .zero }
                    lastInteractionTime = animationTime
                }
            )
            .simultaneousGesture(TapGesture(count: 2).onEnded { if !isRingMode { switchShape() } })
            .onReceive(Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()) { _ in
                animationTime = Date().timeIntervalSinceReferenceDate
                if animationTime - lastInteractionTime > 6, !isTransitioning, selectedParticle == nil, !isRingMode {
                    switchShape()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: setup)
    }

    // MARK: - Background Starfield
    @ViewBuilder
    private func backgroundLayer(proxy: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.02, green: 0.02, blue: 0.12), location: 0.0),
                    .init(color: Color(red: 0.05, green: 0.03, blue: 0.20), location: 0.45),
                    .init(color: Color(red: 0.00, green: 0.00, blue: 0.08), location: 1.0),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ForEach(stars) { star in
                let twinkle = 0.3 + 0.7 * abs(sin(animationTime * 0.9 + star.twinkleOffset))
                Circle()
                    .fill(Color.white.opacity(star.opacity * twinkle))
                    .frame(width: star.size, height: star.size)
                    .position(x: star.x * proxy.size.width, y: star.y * proxy.size.height)
            }
        }
    }

    // MARK: - Nebula Glow
    @ViewBuilder
    private func nebulaLayer(proxy: GeometryProxy) -> some View {
        let pulse = 0.12 + 0.05 * sin(animationTime * 0.25)
        let heartPulse: Double = currentShape == .heart ? 0.22 : 0
        ZStack {
            RadialGradient(colors: [Color.purple.opacity(pulse), .clear],
                           center: .center, startRadius: 0, endRadius: proxy.size.width * 0.55)
            RadialGradient(colors: [Color.blue.opacity(pulse * 0.7), .clear],
                           center: UnitPoint(x: 0.18, y: 0.25), startRadius: 0, endRadius: proxy.size.width * 0.4)
            RadialGradient(colors: [Color.pink.opacity(heartPulse), .clear],
                           center: .center, startRadius: 0, endRadius: proxy.size.width * 0.65)
                .animation(.easeInOut(duration: 1.2), value: currentShape)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle View
    @ViewBuilder
    private func particleView(item: ImageParticle, proxy: GeometryProxy) -> some View {
        let rotY = isRingMode
            ? animationTime * 0.5 + Double(dragOffset.width) / 55.0
            : animationTime * 0.10 + Double(dragOffset.width / 160)
        let rotX = isRingMode
            ? 0.38
            : animationTime * 0.07 + Double(dragOffset.height / 160)
        let pos = positionFor(item, in: proxy.size)
        let rotated = rotate(pos, x: rotX, y: rotY)
        let proj = project(rotated, in: proxy.size)
        let size = isRingMode
            ? CGFloat(90 + 55 * proj.scale)
            : CGFloat(55 + 25 * proj.scale)

        particleContent(item: item, img: images[item.id], size: size, proj: proj)
        .position(x: proj.x, y: proj.y)
        .opacity(0.25 + proj.scale * 0.75)
        .animation(.interpolatingSpring(stiffness: 60, damping: 12), value: currentShape)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedParticle = item
            }
            lastInteractionTime = animationTime
        }
        .allowsHitTesting(selectedParticle == nil && !isTransitioning)
    }

    private var glowColor: Color {
        switch currentShape {
        case .heart: return .pink
        case .dna:   return .green
        default:     return .cyan
        }
    }

    @ViewBuilder
    private func particleContent(item: ImageParticle, img: UIImage?, size: CGFloat, proj: (x: CGFloat, y: CGFloat, scale: CGFloat)) -> some View {
        let displayImage = img ?? UIImage(named: "ai_test")
        Image(uiImage: displayImage ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(clipShape(for: item))
            .overlay(clipShape(for: item).stroke(Color.white.opacity(0.25 * proj.scale), lineWidth: 1))
            .shadow(color: glowColor.opacity(0.35 * proj.scale), radius: 6)
            .opacity(img == nil ? 0.45 : 1.0)
    }

    private func clipShape(for item: ImageParticle) -> AnyShape {
        switch currentShape {
        case .heart:     return AnyShape(HeartShape())
        case .scattered: return [AnyShape(Circle()), AnyShape(RoundedRectangle(cornerRadius: 7)), AnyShape(HeartShape())][item.index % 3]
        default:         return AnyShape(Circle())
        }
    }

    // MARK: - UI Overlay Layer
    @ViewBuilder
    private func overlayUI(proxy: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("IMAGE GALAXY")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.linearGradient(
                            colors: isRingMode ? [.white, .cyan] : (currentShape == .heart ? [.pink, .purple] : [.cyan, .purple]),
                            startPoint: .leading, endPoint: .trailing))
                        .animation(.easeInOut(duration: 0.5), value: currentShape)

                    if isRingMode {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise.circle").font(.caption2)
                            Text("RING MODE").font(.caption2.weight(.semibold))
                        }
                        .foregroundColor(.white.opacity(0.65))

                        Text("Drag to spin")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.38))
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: currentShape.icon).font(.caption2)
                            Text(currentShape.displayName).font(.caption2.weight(.semibold))
                        }
                        .foregroundColor(.white.opacity(0.65))
                        .animation(.easeInOut(duration: 0.3), value: currentShape)

                        Text("Double-tap to transform")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.38))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, proxy.safeAreaInsets.top + 56)

            Spacer()

            if !isRingMode {
                HStack(spacing: 10) {
                    ForEach(GalaxyShape.allCases, id: \.self) { shape in
                        Capsule()
                            .fill(shape == currentShape ? Color.white : Color.white.opacity(0.28))
                            .frame(width: shape == currentShape ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentShape)
                    }
                }
                .padding(.bottom, 44)
            }
        }
    }

    // MARK: - Full-Screen Viewer
    @ViewBuilder
    private func fullScreenViewer(particle: ImageParticle, proxy: GeometryProxy) -> some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
                .onTapGesture { dismissViewer() }

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: dismissViewer) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                .padding(.top, proxy.safeAreaInsets.top + 32)

                Spacer()

                if let img = images[particle.id] {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: proxy.size.width * 0.85, maxHeight: proxy.size.height * 0.62)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .white.opacity(0.18), radius: 24)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
                } else {
                    Image("img_loading")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .opacity(0.5)
                }

                Spacer()
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func dismissViewer() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            selectedParticle = nil
        }
        lastInteractionTime = animationTime
    }

    // MARK: - Shape Switch
    private func switchShape() {
        guard !isTransitioning else { return }
        isTransitioning = true
        lastInteractionTime = animationTime
        withAnimation(.spring(response: 1.1, dampingFraction: 0.72)) {
            currentShape = currentShape.next()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isTransitioning = false
        }
    }

    // MARK: - Depth Sort (z-axis from large to small = from far to near, ensuring near particles render on top)
    private func depthSortedParticles(in proxy: GeometryProxy) -> [ImageParticle] {
        let rotY = isRingMode
            ? animationTime * 0.5 + Double(dragOffset.width) / 55.0
            : animationTime * 0.10 + Double(dragOffset.width / 160)
        let rotX = isRingMode ? 0.38 : animationTime * 0.07 + Double(dragOffset.height / 160)
        return particles.sorted { a, b in
            let za = rotate(positionFor(a, in: proxy.size), x: rotX, y: rotY).z
            let zb = rotate(positionFor(b, in: proxy.size), x: rotX, y: rotY).z
            return za > zb  // larger z = farther away, rendered earlier, stays at the bottom layer
        }
    }

    // MARK: - Position Calculation
    private func positionFor(_ particle: ImageParticle, in size: CGSize) -> SIMD3<Double> {
        if isRingMode {
            return ringPoint(index: particle.index, total: particles.count)
        }
        let total = max(particles.count - 1, 1)
        let t = Double(particle.index) / Double(total)
        switch currentShape {
        case .sphere:    return spherePoint(index: particle.index, total: particles.count, radius: 155)
        case .heart:     return heartPoint(t: t, radius: 125)
        case .spiral:    return spiralPoint(index: particle.index, time: animationTime)
        case .dna:       return dnaPoint(index: particle.index, time: animationTime)
        case .scattered: return scatteredPoint(for: particle, in: size)
        }
    }

    private func ringPoint(index: Int, total: Int) -> SIMD3<Double> {
        let angle = 2 * Double.pi * Double(index) / Double(max(total, 1))
        let radius: Double = 160
        return SIMD3(radius * sin(angle), 0, radius * cos(angle))
    }

    private func spherePoint(index: Int, total: Int, radius: Double) -> SIMD3<Double> {
        let phi   = acos(1 - 2 * Double(index) / Double(max(total, 1)))
        let theta = Double(index) * .pi * (3 - sqrt(5))
        return SIMD3(radius * sin(phi) * cos(theta),
                     radius * sin(phi) * sin(theta),
                     radius * cos(phi))
    }

    private func heartPoint(t: Double, radius: Double) -> SIMD3<Double> {
        let a = t * 2 * .pi
        // Classic heart parametric equations
        let x =  radius * 0.85 * pow(sin(a), 3)
        let y = -radius * 0.78 * (13*cos(a) - 5*cos(2*a) - 2*cos(3*a) - cos(4*a)) / 16.0
        return SIMD3(x, y, 0)
    }

    private func spiralPoint(index: Int, time: Double) -> SIMD3<Double> {
        let t     = Double(index) / Double(max(particles.count - 1, 1))
        let angle = t * 5 * .pi + time * 0.08
        let r     = 40 + 130 * t
        return SIMD3(r * cos(angle), (t - 0.5) * 320, r * sin(angle))
    }

    private func dnaPoint(index: Int, time: Double) -> SIMD3<Double> {
        let t      = Double(index) / Double(max(particles.count - 1, 1))
        let strand = (index % 2 == 0) ? 0.0 : Double.pi
        let angle  = t * 5 * .pi + strand + time * 0.06
        let r: Double = 80
        return SIMD3(r * cos(angle), (t - 0.5) * 320, r * sin(angle))
    }

    private func scatteredPoint(for particle: ImageParticle, in size: CGSize) -> SIMD3<Double> {
        let seed  = abs(particle.id.hashValue)
        let x     = Double(seed % 1000) / 1000.0 * Double(size.width)  - Double(size.width)  / 2
        let y     = Double((seed / 1000) % 1000) / 1000.0 * Double(size.height) - Double(size.height) / 2
        let z     = Double((seed / 1_000_000) % 1000) / 1000.0 * 200 - 100
        return SIMD3(x, y, z)
    }

    // MARK: - 3D Transform
    private func rotate(_ p: SIMD3<Double>, x: Double, y: Double) -> SIMD3<Double> {
        let (sY, cY) = (sin(y), cos(y))
        let (sX, cX) = (sin(x), cos(x))
        var q = SIMD3(p.x * cY + p.z * sY, p.y, -p.x * sY + p.z * cY)
        q = SIMD3(q.x, q.y * cX - q.z * sX, q.y * sX + q.z * cX)
        return q
    }

    private func project(_ p: SIMD3<Double>, in size: CGSize) -> (x: CGFloat, y: CGFloat, scale: CGFloat) {
        let fov: Double = 700
        let s = fov / (fov + p.z + 100)
        return (CGFloat(p.x * s) + size.width / 2,
                CGFloat(p.y * s) + size.height / 2,
                CGFloat(s))
    }

    // MARK: - Initialization
    private func setup() {
        setupStars()
        loadPhotos()
        lastInteractionTime = Date().timeIntervalSinceReferenceDate
    }

    private func setupStars() {
        stars = (0..<130).map { _ in
            StarParticle(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 0.5...2.5),
                opacity: .random(in: 0.2...0.85),
                twinkleOffset: .random(in: 0...(2 * .pi))
            )
        }
    }

    private func loadPhotos() {
        Task {
            // ── Step 1: Authorization Status ──
            let status = PHPhotoLibrary.authorizationStatus()
            print("[Galaxy] Step1 - Auth status: \(status.rawValue)  (0=notDetermined 1=restricted 2=denied 3=authorized 4=limited)")

            let granted: Bool
            if status == .notDetermined {
                let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                granted = result == .authorized || result == .limited
                print("[Galaxy] Step1 - Auth request result: \(result.rawValue)  granted=\(granted)")
            } else {
                granted = status == .authorized || status == .limited
            }

            guard granted else {
                print("[Galaxy] Step1 - Permission denied")
                return
            }

            // ── Step 2: Fetch Photo Library Assets ──
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            opts.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(with: opts)

            let maxParticles = 200
            var assets: [PHAsset] = []
            result.enumerateObjects { asset, _, stop in
                assets.append(asset)
                if assets.count >= maxParticles { stop.pointee = true }
            }
            print("[Galaxy] Step2 - Assets fetched: \(assets.count)  (limit \(maxParticles))")

            let newParticles = assets.enumerated().map { i, asset in
                ImageParticle(asset: asset, index: i)
            }
            await MainActor.run { particles = newParticles }
            print("[Galaxy] Step2 - particles written to MainActor, total: \(newParticles.count)")

            // ── Step 3: Concurrent Thumbnail Loading ──
            var successCount = 0
            var failCount = 0
            await withTaskGroup(of: Void.self) { group in
                for particle in newParticles {
                    guard let asset = particle.asset else { continue }
                    let pid = particle.id
                    group.addTask {
                        let img = await self.loadThumbnail(asset)
                        if let img = img {
                            await MainActor.run {
                                self.images[pid] = img
                                successCount += 1
                                print("[Galaxy] Step3 - Load success [\(successCount)] size=\(img.size)")
                            }
                        } else {
                            await MainActor.run {
                                failCount += 1
                                print("[Galaxy] Step3 - Load failed [\(failCount)] asset=\(asset.localIdentifier)")
                            }
                        }
                    }
                }
            }
            print("[Galaxy] Step3 - All done  success:\(successCount) failed:\(failCount)  images count:\(images.count)")
        }
    }

    private func loadThumbnail(_ asset: PHAsset) async -> UIImage? {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .opportunistic
        opts.isNetworkAccessAllowed = true
        opts.resizeMode = .fast
        opts.version = .current

        return await withCheckedContinuation { c in
            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: opts
            ) { img, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let inCloud    = (info?[PHImageResultIsInCloudKey]  as? Bool) ?? false
                let error      = info?[PHImageErrorKey] as? Error
                let cancelled  = (info?[PHImageCancelledKey]        as? Bool) ?? false

                print("[Galaxy] loadThumbnail callback - asset=\(asset.localIdentifier.prefix(8)) img=\(img != nil) isDegraded=\(isDegraded) inCloud=\(inCloud) cancelled=\(cancelled) error=\(error?.localizedDescription ?? "nil")")

                // Still degraded, wait for the final result
                if isDegraded { return }

                guard !resumed else { return }
                resumed = true
                c.resume(returning: img)
            }
        }
    }
}
