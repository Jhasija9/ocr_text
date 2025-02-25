import SwiftUI
import Vision
import UIKit

struct ContentView: View {
    @State private var recognizedTexts: [String] = []

    var body: some View {
        VStack {
            Text("Recognized Text:")
                .font(.headline)
            // Display the recognized texts
            ForEach(recognizedTexts, id: \.self) { text in
                Text(text)
            }
        }
        .onAppear {
            processImageForText()
        }
    }

    /// Perform text recognition on an image in your Assets (e.g. "sampleImage")
    func processImageForText() {
        // 1. Load the image from your Assets
        guard let uiImage = UIImage(named: "IMG_9681.jpg") else {
            print("Image not found in Assets")
            return
        }

        // 2. Convert to CIImage
        guard let ciImage = CIImage(image: uiImage) else {
            print("Failed to convert UIImage to CIImage")
            return
        }

        // 3. Create a Vision request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text found.")
                return
            }

            // 4. Gather recognized text
            var tempTexts = [String]()
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    tempTexts.append(candidate.string)
                }
            }

            // 5. Update the UI on the main thread
            DispatchQueue.main.async {
                recognizedTexts = tempTexts
            }
        }

        // Use a more accurate recognition level
        request.recognitionLevel = .accurate

        // 6. Create a request handler
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        // 7. Perform the request on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error.localizedDescription)")
            }
        }
    }
}
