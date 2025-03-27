import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    // Modified to handle current scan type
    @Binding var image: UIImage?
    @Binding var isShown: Bool
    var scanType: ScanType  // Add this to show which type of scan
    var onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        
        // Add custom title based on scan type
        picker.navigationItem.title = scanType.title
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update title if needed
        uiViewController.navigationItem.title = scanType.title
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                print("📸 Captured image for: \(parent.scanType.title)")
                parent.onCapture(image)
            }
            parent.isShown = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ Camera cancelled for: \(parent.scanType.title)")
            parent.isShown = false
        }
    }
}
