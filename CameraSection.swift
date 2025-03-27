import SwiftUI
import UIKit

enum ScanType {
    case largeLabel
    case coa
    case vial
    
    var title: String {
        switch self {
        case .largeLabel: return "Scan Large Label"
        case .coa: return "Scan Certificate of Analysis"
        case .vial: return "Scan Vial"
        }
    }
}

struct CameraSection: View {
    @Binding var capturedImages: [ScanType: UIImage]  // Store image for each scan type
    @Binding var showCamera: Bool
    @State private var currentScanType: ScanType = .largeLabel
    
    var body: some View {
        VStack(spacing: 20) {
            // Display captured images or camera icons
            ForEach([ScanType.largeLabel, .coa, .vial], id: \.self) { scanType in
                VStack(spacing: 10) {
                    if let image = capturedImages[scanType] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .frame(height: 80)
                    }
                    
                    Button(action: {
                        currentScanType = scanType
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text(scanType.title)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(capturedImages[scanType] == nil ? Color.blue : Color.green)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}
