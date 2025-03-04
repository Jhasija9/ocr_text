import SwiftUI
import UIKit

struct CameraSection: View {
    @Binding var capturedImage: UIImage?
    @Binding var showCamera: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(height: 100)
            }
            
            Button(action: {
                showCamera = true
            }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Scan Document")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
