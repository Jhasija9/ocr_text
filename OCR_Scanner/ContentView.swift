import SwiftUI
import Vision
import UIKit

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class FieldMatcher {
    // Field identifier groups
    static let fieldIdentifiers = [
        "Radiopharmaceutical": ["Product", "Prod"],
        "Rx": ["RX#", "Rx#"],
        "PatientID": ["Patient:", "Patient :", "Patient.", "Subject:", "Subject :"],
        "ActualAmount": ["Disp Amt :", "Actual Amt :", "Actual Amount :"],
        "CalibrationDate": ["Cal", "Calibration", "elibration"],
        "LotNumber": ["Lot", "BOSEN", "Batch","Lo#"],
        "OrderedAmount": ["Ordered Amount:", "Ordered Amount :", "Order Amount:", "Order Amt:"],
        "Volume": ["Volume:", "Volume :", "Vol:", "Vol :"],
        "Manufacturer": ["Manufacturer:", "Manufacturer :", "Mfr:", "Mfr :"],
    ]
    
    // Fuzzy matching for field identifiers
    static func findField(in text: String) -> (fieldType: String, confidence: Double)? {
            let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            var bestMatch: (fieldType: String, confidence: Double) = ("", 0.0)
            if text.starts(with: "Disp Amt :") {
                    return ("ActualAmount", 1.0)
                }
            
            for (fieldType, identifiers) in fieldIdentifiers {
                for identifier in identifiers {
                    // Remove colons and spaces for comparison
                    let cleanIdentifier = identifier.lowercased()
                        .replacingOccurrences(of: ":", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let cleanInputText = cleanText
                        .replacingOccurrences(of: ":", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Check if text starts with the identifier
                    if cleanInputText.starts(with: cleanIdentifier) {
                        bestMatch = (fieldType, 1.0)  // Perfect match
                        break
                    }
                    
                    // If not an exact match, try fuzzy matching
                    let confidence = calculateConfidence(cleanInputText, cleanIdentifier)
                    if confidence > bestMatch.confidence && confidence > 0.7 {
                        bestMatch = (fieldType, confidence)
                    }
                }
            }
            
            return bestMatch.confidence > 0 ? bestMatch : nil
        }
    
    // Calculate confidence using fuzzy matching
    static func calculateConfidence(_ text: String, _ identifier: String) -> Double {
        // Check if text contains the identifier with typos
        var maxConfidence = 0.0
        
        // Sliding window approach for partial matches
        let words = text.split(separator: " ")
        for word in words {
            let distance = levenshteinDistance(String(word), identifier)
            let length = Double(max(word.count, identifier.count))
            let confidence = 1.0 - (Double(distance) / length)
            maxConfidence = max(maxConfidence, confidence)
        }
        
        return maxConfidence
    }
    
    // Levenshtein distance calculation
    static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let empty = Array(repeating: 0, count: b.count + 1)
        var last = Array(0...b.count)
        
        for (i, a_char) in a.enumerated() {
            var current = [i + 1] + empty
            for (j, b_char) in b.enumerated() {
                current[j + 1] = min(
                    last[j + 1] + 1,
                    current[j] + 1,
                    last[j] + (a_char == b_char ? 0 : 1)
                )
            }
            last = current
        }
        return last[b.count]
    }
}

struct ContentView: View {
    @State private var formData = FormData()
    @State private var isLoading = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isScanComplete = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentUser = "TestUser"
    @State private var showVialScanForm = false
    @State private var savedRx: String = ""

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
//                    CameraSection(
//                        capturedImage: $capturedImage,
//                        showCamera: $showCamera
//                    )
//                    
//                    FormSection(formData: $formData)
//                    
//                    if isScanComplete {
//                        AttestButton {
//                            Task {
//                                await saveToDatabase()
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("OCR Form Scanner")
//            .sheet(isPresented: $showCamera) {
//                CameraView(image: $capturedImage, isShown: $showCamera) { image in
//                    processImage(image)
//                    isScanComplete = true
//                }
//            }
            if !showVialScanForm {
                                    // Main Form
                                    CameraSection(
                                        capturedImage: $capturedImage,
                                        showCamera: $showCamera
                                    )
                                    
                                    FormSection(formData: $formData)
                                    
                                    if isScanComplete {
                                        AttestButton {
                                            Task {
                                                await saveToDatabase()
                                            }
                                        }
                                    }
                                } else {
                                    // Show Vial Scan after successful attestation
                                    VialScanView(originalRx: savedRx)
                                }
                            }
                            .padding()
                        }
                        // UPDATE NAVIGATION TITLE TO SHOW CORRECT FORM NAME
                        .navigationTitle(showVialScanForm ? "Vial Scan" : "OCR Form Scanner")
                        .sheet(isPresented: $showCamera) {
                            CameraView(image: $capturedImage, isShown: $showCamera) { image in
                                processImage(image)
                                isScanComplete = true
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
                    title: Text("Database Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func processImage(_ image: UIImage) {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("Starting image processing...")
        isLoading = true
        
        // Convert to CIImage
        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert UIImage to CIImage")
            isLoading = false
            return
        }
        print("✅ Successfully converted to CIImage")
        
        // Create a Vision request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text found.")
                isLoading = false
                return
            }
            print("✅ Found \(observations.count) text observations")
            
            // Gather recognized text
            let texts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            print("📝 Recognized texts: \(texts)")
            
            DispatchQueue.main.async {
                print("Starting text parsing...")  // Debug log
                parseRecognizedText(texts)
                print("✅ Finished parsing text")
                isLoading = false
            }
        }
        
        // Use accurate recognition level
        request.recognitionLevel = .accurate
        print("Recognition level set to accurate")
        
        // Create request handler
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Perform request
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("Performing text recognition...")
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        print("Processing time: \(endTime - startTime) seconds")
    }
    
    private func parseRecognizedText(_ texts: [String]) {
        formData = FormData()
        var bestPatientID: (value: String, confidence: Double) = ("", 0.0)
        
        for (index, text) in texts.enumerated() {
            print("\nProcessing: \(text)")
            
            // Use fuzzy matching to identify fields
            if let (fieldType, confidence) = FieldMatcher.findField(in: text) {
                print("Found field: \(fieldType) with confidence: \(confidence)")
                
                // Extract value (from same line or next line)
                var value = ""
                if let colonRange = text.range(of: ":|#|-", options: .regularExpression) {
                    value = String(text[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if let nextText = texts[safe: index + 1] {
                    value = nextText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Update form data based on field type
                switch fieldType {
                case "Radiopharmaceutical":
                    formData.Radiopharmaceutical = value
                    print("✅ Study Name: \(value)")
                case "Rx":
                    formData.rx = value.replacingOccurrences(of: "[^0-9]", with: "")
                    print("✅ Rx: \(value)")
                case "PatientID":
                    if confidence > bestPatientID.confidence && !value.isEmpty {
                                            bestPatientID = (value, confidence)
                                            print("✅ Better Patient ID found: \(value)")
                                        }
                case "ActualAmount":
                    formData.ActualAmount = value  // Still sets ActualAmount in formData
                    print("✅ Actual Amount: \(value)")
                                    
                case "CalibrationDate":
                    formData.calibrationDate = value
                    print("✅ Calibration Date: \(value)")
                case "LotNumber":
                    let cleanValue = value.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    formData.lotNumber = cleanValue
                    print("✅ Lot Number: \(cleanValue)")
                case "OrderedAmount":
                    formData.OrderedAmount = value
                    print("✅ Ordered Amount: \(value)")
                case "Volume":
                    formData.Volume = value
                    print("✅ Volume: \(value)")
                case "Manufacturer":
                    formData.Manufacturer = value
                    print("✅ Manufacturer: \(value)")
                default:
                    break
                }
            }
        }
        formData.patientID = bestPatientID.value
        // Debug print results
        print("\nExtracted Values (with fuzzy matching):")
        print("Study Name: \(formData.Radiopharmaceutical)")
        print("Rx: \(formData.rx)")
        print("Patient ID: \(formData.patientID)")
        print("Actual Amount: \(formData.ActualAmount)")
        print("Calibration Date: \(formData.calibrationDate)")
        print("Lot Number: \(formData.lotNumber)")
        print("Ordered Amount: \(formData.OrderedAmount)")
        print("Volume: \(formData.Volume)")
        print("Manufacturer: \(formData.Manufacturer)")
    }
    
    // Add the Array extension at the bottom of the file
    
    
    private func saveToDatabase() async {
        DatabaseManager.shared.saveFormData(formData: formData, currentUser: currentUser)
            .map { _ in
                DispatchQueue.main.async {
                    self.alertMessage = "Successfully saved to database"
                    self.showAlert = true
                    print("✅ Data saved successfully")
                    self.savedRx = self.formData.rx
                    self.resetForm()
                    self.showVialScanForm = true
}
            }
            .whenFailure { error in
                DispatchQueue.main.async {
                    self.alertMessage = "Error saving to database: \(error.localizedDescription)"
                    self.showAlert = true
                    print("❌ Database error: \(error)")
                }
            }
        
    }
    private func resetForm() {
        print("Starting form reset...")
        formData = FormData()
        capturedImage = nil
        isScanComplete = false
        print("Form data after reset: \(formData)") // Debug print
        print("isScanComplete after reset: \(isScanComplete)") // Debug print}
    }
    // Preview provider
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
