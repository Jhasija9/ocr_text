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
    @State private var capturedImages: [ScanType: UIImage] = [:]
    @State private var currentScanType: ScanType = .largeLabel
    @State private var vialRx: String = ""
    @State private var rxMatchStatus: String = ""
    @State private var showRxComparison = false
    @State private var showRxAlert = false
    @State private var showSimpleAlert = false
//    @State private var showPhotoAlert = false
    @State private var showPhotoAlert = false
    @State private var photoAlertTitle = ""
    @State private var photoAlertMessage = ""
    @State private var rxAlertMessage = ""
    @State private var matchedRx: String = ""
    @State private var showNoRxAlert = false
    @State private var isMatchedRxEditable = false
    @State private var showRxInputAlert = false  // For the Yes/No popup
    @State private var showSingleRxInput = false // For showing single RX input field
    @State private var singleRxNumber = ""
    @State private var isAttesting = false
    @State private var attestationError: String?
    @State private var alertTitle = ""
    @State private var labelRxConfirmed = false
    @State private var vialRxConfirmed = false
    @State private var patientIdConfirmed = false
    @State private var isRetakingPhoto = false
    @State private var newPhotoType: ScanType?
    @State private var showQRAlert = false
    @State private var newLabelImage: UIImage?  // Store new label photo separately
    @State private var newVialImage: UIImage?   // Store new vial photo separately
    @State private var tempFormData: FormData?   // Store form data temporarily during retake
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {  // Add VStack wrapper
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
                    
                    // Add RX comparison section
                    VStack {
                        Text("RX Comparison")
                            .font(.headline)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Large Label RX:").font(.headline)
                                TextField("Enter Label RX", text: $formData.rx)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            HStack {
                                Image(systemName: labelRxConfirmed ? "checkmark.square.fill" : "square")
                                    .foregroundColor(labelRxConfirmed ? .green : .gray)
                                    .onTapGesture {
                                        labelRxConfirmed.toggle()
                                    }
                                Text("I confirm that RX number is same as on label")
                                    .font(.caption)
                            }
                            .padding(.top, 4)
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Vial RX:").font(.headline)
                                TextField("Enter Vial RX", text: $formData.vialRx)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            HStack {
                                Image(systemName: vialRxConfirmed ? "checkmark.square.fill" : "square")
                                    .foregroundColor(vialRxConfirmed ? .green : .gray)
                                    .onTapGesture {
                                        vialRxConfirmed.toggle()
                                    }
                                Text("I confirm that RX number is same as on vial")
                                    .font(.caption)
                            }
                            .padding(.top, 4)
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Patient ID:")
                                    .font(.headline)
                                TextField("Enter Patient ID", text: $formData.patientID)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Checkbox for Patient ID
                            HStack {
                                Image(systemName: patientIdConfirmed ? "checkmark.square.fill" : "square")
                                    .foregroundColor(patientIdConfirmed ? .green : .gray)
                                    .onTapGesture {
                                        patientIdConfirmed.toggle()
                                    }
                                Text("I confirm that Patient ID matches the large label")
                                    .font(.caption)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        
                        // CHANGE: Update status message based on RX comparison
                        if !formData.rx.isEmpty && !formData.vialRx.isEmpty {
                            if formData.rx == formData.vialRx {
                                Label("RX Numbers Match!", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label("RX Numbers Don't Match! Please verify or scan correct vial",
                                      systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                            }
                        } else {
                            if formData.rx.isEmpty {
                                Text("Please enter or scan Label RX")
                                    .foregroundColor(.blue)
                                // Add button to use Vial's RX and print QR
                                if !formData.vialRx.isEmpty {
                                    Button("Use Vial RX & Print QR") {
                                        Task {
                                            // 1. Send Vial RX to printer
                                            await sendToQRPrinter(rx: formData.vialRx)
                                            
                                            // 2. Show camera for new photo
                                            currentScanType = .largeLabel
                                            showCamera = true
                                        }
                                    }
                                }
                            }
                            
                            if formData.vialRx.isEmpty {
                                Text("Please enter or scan Vial RX")
                                    .foregroundColor(.blue)
                                if !formData.rx.isEmpty {
                                    Button("Use Label RX & Print QR") {
                                        Task {
                                            await sendToQRPrinter(rx: formData.rx)
                                            currentScanType = .vial
                                            showCamera = true
                                        }
                                    }
                                }
                            }
                        }}
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    //
                    VStack(spacing: 15) {
                        Text("Matched RX Number:")
                            .font(.headline)
                        
                        if formData.rx == formData.vialRx && !formData.rx.isEmpty {
                            Text(formData.rx)
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("By clicking Attest, I confirm that all information is correct and verified")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            AttestButton(action: {
                                Task {
                                    await saveToDatabase()
                                }
                            }, isLoading: isAttesting)
                        } else {
                            Text("Waiting for matching RX numbers...")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                }
                .padding()
            }
            .navigationTitle("OCR Form Scanner")
            .sheet(isPresented: $showCamera) {
                CameraView(
                    image: Binding(
                        get: { if isRetakingPhoto {
                            return currentScanType == .largeLabel ? newLabelImage : newVialImage
                        } else {
                            return capturedImages[currentScanType]
                        } },
                        set: { newImage in
                            if isRetakingPhoto {
                                if currentScanType == .largeLabel {
                                    newLabelImage = newImage
                                } else {
                                    newVialImage = newImage
                                }
                            } else {
                                capturedImages[currentScanType] = newImage
                            }
                        }
                    ),
                    isShown: $showCamera,
                    scanType: currentScanType
                ) { image in
                    processImage(image)
                    if currentScanType == .largeLabel {
                        isScanComplete = true
                    }
                }
            }
            // ✅ Add this inside body, before the .sheet or at the top of VStack:
            


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
            .alert(isPresented: $showPhotoAlert) {
                Alert(
                    title: Text(photoAlertTitle),
                    message: Text(photoAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("RX Number Check", isPresented: $showRxInputAlert) {
                Button("Yes") {
                    showSingleRxInput = true
                }
                Button("No") {
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let autoRx = "MDCH\(timestamp)"
                    formData.rx = autoRx
                    formData.vialRx = autoRx
                    Task {
                                await sendToQRPrinter(rx: autoRx)
                                DispatchQueue.main.async {
                                    self.rxAlertMessage = "Please take a photo of the vial with QR code"
                                    self.showRxAlert = true
                                    self.isRetakingPhoto = true
                                    self.currentScanType = .largeLabel
                                }
                            }
                        
                }
            } message: {
                Text("Did you find any RX number on papers?")
            }
            
            // Add this alert for single RX input
            .alert("Enter RX Number", isPresented: $showSingleRxInput) {
                TextField("RX Number", text: $singleRxNumber)
                    .keyboardType(.numberPad)
                
                Button("OK") {
                    if !singleRxNumber.isEmpty {
                        formData.rx = singleRxNumber
                        formData.vialRx = singleRxNumber
                        singleRxNumber = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    singleRxNumber = ""
                }
            } message: {
                Text("Please enter the RX number found on papers")
            }
            
            .alert(isPresented: $showRxAlert) {
                Alert(
                    title: Text("RX Verification"),
                    message: Text(rxAlertMessage),
                    primaryButton: .default(Text("Take Photo")) {
                        Task {
                            // First copy the RX
                            if formData.rx.isEmpty && !formData.vialRx.isEmpty {
                                // Copy Vial RX to Label RX
                                formData.rx = formData.vialRx
                            } else if formData.vialRx.isEmpty && !formData.rx.isEmpty {
                                // Copy Label RX to Vial RX
                                formData.vialRx = formData.rx
                            }
                            
                            isRetakingPhoto = true  // Flag to skip OCR
                            await sendToQRPrinter(rx: formData.vialRx)
                            currentScanType = formData.rx.isEmpty ? .largeLabel : .vial
                            showCamera = true
                        }
                    },
                    secondaryButton: .cancel()
                    
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()).alert(isPresented: $showAlert) {
            Alert(
                title: Text("Database Update"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }}
    
    private func processImage(_ image: UIImage) {
        if isRetakingPhoto {
            // Just store the image, no OCR
            if currentScanType == .largeLabel {
                newLabelImage = image
                Task {
                            do {
                                let labelUrl = try await S3Manager.shared.uploadImage(
                                    image,
                                    rxNumber: formData.rx,
                                    scanType: .largeLabel
                                )
                                formData.newLabelImageUrl = labelUrl
                                
                                DispatchQueue.main.async {
                                    self.photoAlertTitle = "Photo Upload"
                                    self.photoAlertMessage = "Please take a photo of the vial with QR code"
                                    self.showPhotoAlert = true
                                    self.currentScanType = .vial
                                    self.showCamera = true
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.photoAlertTitle = "Upload Error"
                                    self.photoAlertMessage = "Failed to upload label photo: \(error.localizedDescription)"
                                    self.showPhotoAlert = true
                                }
                            }
                        }
                    } else if currentScanType == .vial {
                        newVialImage = image
                        Task {
                            do {
                                let vialUrl = try await S3Manager.shared.uploadImage(
                                    image,
                                    rxNumber: formData.rx,
                                    scanType: .vial
                                )
                                formData.newVialImageUrl = vialUrl
                                
                                DispatchQueue.main.async {
                                    self.photoAlertTitle = "Photo Upload"
                                    self.photoAlertMessage = "Photos uploaded successfully"
                                    self.showPhotoAlert = true
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.photoAlertTitle = "Upload Error"
                                    self.photoAlertMessage = "Failed to upload vial photo: \(error.localizedDescription)"
                                    self.showPhotoAlert = true
                                }
                            }
                        }
                    }
                    isRetakingPhoto = false
                    isLoading = false
                    return
                }
//            }
//            isRetakingPhoto = false
//            isLoading = false
//            return
//        }
        let startTime = CFAbsoluteTimeGetCurrent()
//        print("\n=== Starting \(currentScanType.title) Processing ===")
//        isLoading = true
        
        
        if formData.rx.isEmpty && !formData.vialRx.isEmpty {
            Task {
                do {
                    // Upload to S3 with special path
                    let imageUrl = try await S3Manager.shared.uploadImage(
                        image,
                        rxNumber: formData.vialRx,
                        scanType: .largeLabel
                    )
                    
                    // Save URL as new_label_image_url
                    formData.newLabelImageUrl = imageUrl
                    // Use vial's RX for label
                    formData.rx = formData.vialRx
                    print("✅ Saved new label image URL: \(imageUrl)")
                    
                } catch {
                    print("❌ Failed to upload new image: \(error)")
                }
            }
        } else if formData.vialRx.isEmpty && !formData.rx.isEmpty {
            Task {
                do {
                    // Upload to S3 with special path
                    let imageUrl = try await S3Manager.shared.uploadImage(
                        image,
                        rxNumber: formData.rx,
                        scanType: .vial
                    )
                    
                    // Save URL as new_vial_image_url
                    formData.newVialImageUrl = imageUrl
                    // Use label's RX for vial
                    formData.vialRx = formData.rx
                    print("✅ Saved new vial image URL: \(imageUrl)")
                    
                } catch {
                    print("❌ Failed to upload new image: \(error)")
                }
            }
        }
        
        
        
        
        
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
                print("Starting text parsing...")
                
                // Handle different scan types
                switch currentScanType {
                case .largeLabel:
                    parseRecognizedText(texts)  // Existing parsing logic
                case .coa:
                    parseCOAText(texts)  // New COA parsing
                case .vial:
                    parseVialText(texts)  // New vial parsing
                }
                
                print("✅ Finished parsing text")
                isLoading = false
            }
        }
        
        request.recognitionLevel = .accurate
        print("Recognition level set to accurate")
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
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
    private func sendToQRPrinter(rx: String) async {
        // TODO: Replace with actual printer API call
        print("🖨 Printing QR code for RX: \(rx)")
        // Add your printer API integration here
    }
    
    private func parseCOAText(_ texts: [String]) {
        print("\n=== Parsing COA Text ===")
        var toc = ""
        //        var radioactiveConc = ""
        
        // Join all texts for easier searching
        let fullText = texts.joined(separator: " ")
        var coaRadioactiveConc = ""
        
        // Define our search patterns with fuzzy matching
        let tocPatterns = [
            "calibration date and time",
            "calibration date",
            "time of calibration",
            "Specific Activity at toc"
        ]
        
        //        let rocPatterns = [
        //            "radioactivity concentration",
        //            "concentration at toc",
        //            "radioactive concentration",
        //            "activity concentration",
        //            "radioactive concentration at toc"
        //        ]
        
        // Search for TOC using fuzzy logic
        for pattern in tocPatterns {
            let confidence = FieldMatcher.calculateConfidence(fullText.lowercased(), pattern)
            if confidence > 0.7 {
                print("Found TOC pattern with confidence: \(confidence)")
                // Now search for the actual date value
                for text in texts {
                    if text.contains("FEB") && text.contains("ET") && text.contains("2025") {
                        toc = text
                        print("✅ TOC found: \(toc)")
                        break
                    }
                }
                break
            }
        }
        
        // Search for ROC using fuzzy logic
        for (index, text) in texts.enumerated() {
            if text.contains("Radioactivity") && text.contains("Concentration") {
                for i in 1...3 {
                    if let nextText = texts[safe: index + i], nextText.contains("Ci/mL") {
                        coaRadioactiveConc = nextText
                        formData.radioactivityConcentration = coaRadioactiveConc
                        print("✅ Radioactive Concentration found: \(coaRadioactiveConc)")
                        break
                    }
                }
            }
        }
        print("\n=== COA Extraction Results ===")
        print("Time of Calibration (TOC): \(toc)")
        print("Radioactive Concentration: \(coaRadioactiveConc)")
    }
    
    //
    private func parseVialText(_ texts: [String]) {
        print("\n=== Parsing Vial Text ===")
        var foundRx = false
        formData.vialRx = ""
        
        // First extract RX number as we were doing before
        for text in texts {
            let lowercasedText = text.lowercased()
            if lowercasedText.contains("rx") || lowercasedText.contains("rx#"){
                let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .joined()
                if !numbers.isEmpty {
                    formData.vialRx = numbers
                    foundRx = true
                    print("✅ Found Vial RX: \(numbers)")
                    
                    // Case 1: Both RXs exist - Check if they match
                    if !formData.rx.isEmpty {
                        if formData.rx == numbers {
                            print("✅ RX numbers match!")
                            rxAlertMessage = "RX numbers match!"
                            showSimpleAlert = true
                        } else {
                            print("⚠️ Warning: RX numbers don't match!")
                            rxAlertMessage = "RX numbers don't match! Please scan the correct vial or verify RX numbers"
                            showRxAlert = true
                        }
                    }
                    // Case 2: Vial RX exists but Label RX missing
                    else {
                        print("⚠️ No Label RX to compare with")
                        //                            rxAlertMessage = "No Label RX found. Please scan or enter Label RX"
                        //                            showRxAlert = true
                        DispatchQueue.main.async {
                            self.rxAlertMessage = "Would you like to use the Vial RX for the Label?"
                            self.showRxAlert = true
                        }
                    }
                    break
                }
            }
        }
        
        // Case 3: No Vial RX found
        if !foundRx {
            // Case 3a: Label RX exists but no Vial RX
            if !formData.rx.isEmpty {
                formData.vialRx = ""
                print("⚠️ No RX found in vial text")
                rxAlertMessage = "No RX number found on vial. Please attach the QR label to the vial and scan it again"
                showRxAlert = true
            }
            // Case 4: Both RXs missing
            else {
                print("⚠️ No RX numbers found")
                //                rxAlertMessage = "No RX numbers found. Please scan or enter both Label and Vial RX"
                showRxInputAlert = true
            }
        }
        
        print("=== Finished Parsing Vial ===")
    }
    
    
    private func saveToDatabase() async {
        print("\n=== Starting Database Save ===")
        
        
        guard labelRxConfirmed && vialRxConfirmed && patientIdConfirmed  else {
            DispatchQueue.main.async {
                self.alertTitle = "Validation Error"
                self.alertMessage = "Please confirm both RX numbers by checking the boxes"
                self.showAlert = true
            }
            return
        }
        // Validate data first
        guard !formData.rx.isEmpty,
              !formData.patientID.isEmpty,
              !formData.Radiopharmaceutical.isEmpty,
              formData.rx == formData.vialRx else {
            print("❌ Validation failed:")
            print("RX: \(formData.rx)")
            print("Vial RX: \(formData.vialRx)")
            print("Patient ID: \(formData.patientID)")
            print("Radiopharmaceutical: \(formData.Radiopharmaceutical)")
            
            DispatchQueue.main.async {
                self.alertMessage = "Please fill in all required fields and ensure RX numbers match"
                self.showAlert = true
            }
            return
        }
        
        print("✅ Data validation passed")
        print("Saving form data:")
        print("RX: \(formData.rx)")
        print("Patient ID: \(formData.patientID)")
        print("Radiopharmaceutical: \(formData.Radiopharmaceutical)")
        print("Actual Amount: \(formData.ActualAmount)")
        print("Calibration Date: \(formData.calibrationDate)")
        print("Lot Number: \(formData.lotNumber)")
        print("Ordered Amount: \(formData.OrderedAmount)")
        print("Volume: \(formData.Volume)")
        print("Manufacturer: \(formData.Manufacturer)")
        print("Radioactivity Concentration: \(formData.radioactivityConcentration)")
        
        DispatchQueue.main.async {
            self.isAttesting = true
        }
        var imageUrls: [ScanType: String] = [:]
        
        do {
            for (scanType, image) in capturedImages {
                let imageUrl = try await S3Manager.shared.uploadImage(
                    image,
                    rxNumber: formData.rx,
                    scanType: scanType.toImageScanType()
                )
                imageUrls[scanType] = imageUrl
            }
            if let newLabel = newLabelImage {
                let newLabelUrl = try await S3Manager.shared.uploadImage(
                    newLabel,
                    rxNumber: formData.rx,
                    scanType: .largeLabel
                )
                formData.newLabelImageUrl = newLabelUrl
            }
            
            if let newVial = newVialImage {
                let newVialUrl = try await S3Manager.shared.uploadImage(
                    newVial,
                    rxNumber: formData.rx,
                    scanType: .vial
                )
                formData.newVialImageUrl = newVialUrl
            }
            
            
            DatabaseManager.shared.saveFormData(formData: formData, imageUrls: imageUrls, currentUser: currentUser)
                .map { _ in
                    print("✅ Database save successful")
                    DispatchQueue.main.async {
                        self.alertMessage = "Successfully saved to database"
                        self.showAlert = true
                        self.savedRx = self.formData.rx
                        self.resetForm()
                        self.showVialScanForm = true
                        self.capturedImages = [:]
                        self.isAttesting = false
                    }
                }
                .whenFailure { error in
                    print("❌ Database save failed: \(error)")
                    DispatchQueue.main.async {
                        self.alertMessage = "Error saving to database: \(error.localizedDescription)"
                        self.showAlert = true
                        self.isAttesting = false
                    }
                }
        }catch {
            print("❌ Image upload failed: \(error)")
            DispatchQueue.main.async {
                self.alertTitle = "Upload Error"
                self.alertMessage = "Failed to upload images: \(error.localizedDescription)"
                self.showAlert = true
                self.isAttesting = false
            }
        }
    }
    private func resetForm() {
        print("Starting form reset...")
        formData = FormData()
        capturedImage = nil
        isScanComplete = false
        labelRxConfirmed = false  // Reset checkbox states
        vialRxConfirmed = false
        patientIdConfirmed = false
        print("Form data after reset: \(formData)") // Debug print
        print("isScanComplete after reset: \(isScanComplete)") // Debug print}
    }
    private func isDataValid() -> Bool {
        guard !formData.rx.isEmpty,
              !formData.patientID.isEmpty,
              !formData.Radiopharmaceutical.isEmpty,
              formData.rx == formData.vialRx,  // Ensure RX numbers match
              labelRxConfirmed,  // Add this
              vialRxConfirmed
        else {
            return false
        }
        return true
    }
}
