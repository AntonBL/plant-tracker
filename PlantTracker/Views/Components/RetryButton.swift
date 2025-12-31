import SwiftUI

struct RetryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Retry")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

#Preview {
    RetryButton {
        print("Retry tapped")
    }
    .padding()
}
