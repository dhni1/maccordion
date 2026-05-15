import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MaccordionViewModel()
    @State private var keyboardMonitor = KeyboardMonitor()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Maccordion")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("맥북 힌지를 벨로우즈처럼 쓰는 아코디언 프로토타입")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                statCard(title: "Angle", value: String(format: "%.1f°", viewModel.state.angle))
                statCard(title: "Pressure", value: String(format: "%.2f", viewModel.state.pressure))
                statCard(title: "Direction", value: viewModel.state.direction)
                statCard(title: "Note", value: viewModel.state.noteName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Play")
                    .font(.headline)
                Text("`A S D F G H J K L` 키를 누른 채로 화면을 여닫으면 벨로우즈 압력에 따라 소리가 변합니다.")
                    .fixedSize(horizontal: false, vertical: true)
                Text(viewModel.state.status)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.76, blue: 0.36), Color(red: 0.84, green: 0.28, blue: 0.16)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.black.opacity(0.14))
                        .frame(width: max(40, geometry.size.width * min(viewModel.state.pressure + 0.08, 1.0)))
                        .animation(.easeOut(duration: 0.08), value: viewModel.state.pressure)
                }
            }
            .frame(height: 72)
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 320)
        .background(Color(red: 0.98, green: 0.97, blue: 0.93))
        .onAppear {
            keyboardMonitor.start(
                onKeyDown: { event in viewModel.handleKeyDown(event) },
                onKeyUp: { event in viewModel.handleKeyUp(event) }
            )
        }
        .onDisappear {
            keyboardMonitor.stop()
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
