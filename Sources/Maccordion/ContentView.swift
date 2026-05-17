import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MaccordionViewModel()
    @State private var keyboardMonitor = KeyboardMonitor()
    private let pageBackground = Color(red: 0.95, green: 0.93, blue: 0.88)
    private let primaryText = Color(red: 0.14, green: 0.11, blue: 0.09)
    private let secondaryText = Color(red: 0.34, green: 0.28, blue: 0.23)
    private let cardBorder = Color(red: 0.82, green: 0.74, blue: 0.64)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Maccordion")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)

            Text("맥북 힌지를 벨로우즈처럼 쓰는 아코디언 프로토타입")
                .font(.headline)
                .foregroundStyle(secondaryText)

            HStack(spacing: 14) {
                statCard(title: "Angle", value: String(format: "%.1f°", viewModel.state.angle))
                statCard(title: "Pressure", value: String(format: "%.2f", viewModel.state.pressure))
                statCard(title: "Direction", value: viewModel.state.direction)
                statCard(title: "Note", value: viewModel.state.noteName)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Play")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Text("`A S D F G H J K L` 키를 누른 채로 화면을 여닫으면 벨로우즈 압력에 따라 소리가 변합니다.")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(primaryText)
                Text(viewModel.state.status)
                    .foregroundStyle(secondaryText)
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
        .background(pageBackground)
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
                .foregroundStyle(secondaryText)
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
