// NEW FILE: Create this file
import Foundation

enum ImageScanType {    // Changed from ScanType to ImageScanType
    case largeLabel
    case coa
    case vial
}
extension ScanType {
    func toImageScanType() -> ImageScanType {
        switch self {
        case .largeLabel:
            return .largeLabel
        case .coa:
            return .coa
        case .vial:
            return .vial
        }
    }
}
