//
//  FormField.swift
//  OCR_Scanner
//
//  Created by Janesh on 2/28/25.
//

import SwiftUI

struct FormField: View {
    let title: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            TextField(title, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
        }
    }
}
