import SwiftUI
struct AttestButton: View {
    var action: () -> Void
    var isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                Text("Attest")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.green)
            .cornerRadius(10)
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }
}
