//
//  FormSection.swift
//  OCR_Scanner
//
//  Created by Janesh on 3/3/25.
//

//import Foundation
import SwiftUI
struct FormSection: View {
    @Binding var formData: FormData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            FormField(title: "Radiopharmaceutical", value: $formData.Radiopharmaceutical)
            FormField(title: "Rx", value: $formData.rx)
            FormField(title: "Patient/Subject ID", value: $formData.patientID)
            FormField(title: " Actual Amount", value: $formData.ActualAmount)
            FormField(title: "Calibration Date", value: $formData.calibrationDate)
            FormField(title: "Lot/Batch#", value: $formData.lotNumber)
            FormField(title: "Ordered Amount", value: $formData.OrderedAmount)  // New
            FormField(title: "Volume", value: $formData.Volume)                 // New
            FormField(title: "Manufacturer", value: $formData.Manufacturer)
        }
        .padding()
    }
}
