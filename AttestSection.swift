import SwiftUI
struct AttestButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Attest")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
