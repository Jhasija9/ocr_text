import SwiftUI
import Vision
import UIKit

struct VialScanView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
//    @State private var scannedText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showMatchStatus = false
    @State private var isMatch: Bool = false
    let originalRx: String
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Please scan vial and extract the information")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                if showMatchStatus {
                    Text(isMatch ? "RX Numbers Match! ✅" : "RX Numbers Do Not Match! ❌")
                        .font(.headline)
                        .foregroundColor(isMatch ? .green : .red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                }
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
                    Image(systemName: "doc.text.viewfinder")
                    Text("Scan Vial")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            // Display scanned text
//            if !scannedText.isEmpty {
//                VStack(alignment: .leading) {
//                    Text("Scanned Text:")
//                        .font(.headline)
//                        .padding(.top)
//                    ScrollView {
//                        Text(scannedText)
//                            .font(.body)
//                            .padding()
//                    }
//                    .frame(maxHeight: 200)
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(8)
//                }
//                .padding()
//            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage, isShown: $showCamera) { image in
                processVialImage(image)
            }
        }
        .overlay(
            Group {
                if isLoading {
                    ProgressView("Processing...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("RX Verification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func processVialImage(_ image: UIImage) {
        isLoading = true
        print("\n=== Starting Vial Image Processing ===")
        
        guard let ciImage = CIImage(image: image) else {
            print("❌ Failed to convert UIImage to CIImage")
            isLoading = false
            return
        }
        print("✅ Successfully converted to CIImage")
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("❌ Text recognition error: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("❌ No text found in image")
                isLoading = false
                return
            }
            
            print("✅ Found \(observations.count) text observations")
            
            // Process recognized text
            let texts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Print all extracted text
            print("\n=== Extracted Text from Vial ===")
            texts.forEach { text in
                print("📝 Line: \(text)")
            }
            
            DispatchQueue.main.async {
                // Store the scanned text
//                self.scannedText = texts.joined(separator: "\n")
                
                // Find RX in scanned text
                let scannedRx = findRxNumber(in: texts)
                print("\n=== RX Number Extraction ===")
                print("🔍 Searching for RX in scanned text...")
                print("📋 Original RX from form: \(originalRx)")
                print("🏷 Found RX in vial: \(scannedRx)")
                
                // Compare RX numbers
                compareRxNumbers(scannedRx)
                self.isLoading = false
            }
        }
        
        request.recognitionLevel = .accurate
        print("📸 Recognition level set to accurate")
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("🔄 Performing text recognition...")
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform text recognition: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func findRxNumber(in texts: [String]) -> String {
        print("\n🔎 Searching for RX number in text...")
        for text in texts {
            let lowercasedText = text.lowercased()
            print("Checking text: \(text)")
            if lowercasedText.contains("rx") || lowercasedText.contains("rx#") {
                let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .joined()
                if !numbers.isEmpty {
                    print("✅ Found RX number: \(numbers)")
                    return numbers
                }
            }
        }
        print("❌ No RX number found in text")
        return ""
    }
    
//    private func compareRxNumbers(_ scannedRx: String) {
//        print("\n=== Comparing RX Numbers ===")
//        print("📋 Original RX: \(originalRx)")
//        print("🔍 Scanned RX: \(scannedRx)")
//        
//        if scannedRx.isEmpty {
//            alertMessage = "No RX number found in scanned image"
//            print("❌ No RX number found in scanned image")
//            showAlert = true
//            return
//        }
//        
//        if scannedRx == originalRx {
//            alertMessage = "RX numbers match! ✅"
//            print("✅ RX numbers match!")
//            showAlert = true
//        } else {
//            alertMessage = "RX numbers do not match! ❌\nOriginal: \(originalRx)\nScanned: \(scannedRx)"
//            print("❌ RX numbers do not match!")
//            print("Original: \(originalRx)")
//            print("Scanned: \(scannedRx)")
//            showAlert = true
//        }
//    }
    private func compareRxNumbers(_ scannedRx: String) {
            print("\n=== Comparing RX Numbers ===")
            print("📋 Original RX: \(originalRx)")
            print("🔍 Scanned RX: \(scannedRx)")
            
            DispatchQueue.main.async {
                if !scannedRx.isEmpty {
                    self.isMatch = (scannedRx == originalRx)
                } else {
                    self.isMatch = false
                }
                self.showMatchStatus = true
            }
        }
}
