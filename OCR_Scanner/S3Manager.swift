// NEW FILE: Create this new file
import Foundation
import SotoS3
import SotoCore
import UIKit
import NIOCore
import NIOPosix

enum S3Error: Error {
    case imageConversionFailed
    case uploadFailed(Error)
    case initializationError
}

class S3Manager {
    static let shared = S3Manager()
    private let s3: SotoS3.S3
    private let bucketName = "unithera-dev-raminventory"
    private let eventLoopGroup: EventLoopGroup
    
    // Define paths for different image types
    private enum S3Path {
        static let largeLabel = "largeLabel/"
        static let coa = "coa/"
        static let vial = "pharma-documents/"
    }
    
    private init() {
        // Initialize EventLoopGroup
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        // Create AWS client
        let client = AWSClient(
            credentialProvider: .static(
                accessKeyId: "AKIASODIIJ7ROCGS3FPB",
                secretAccessKey: "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"
            )
        )
        
        // Initialize S3 client with region
        self.s3 = SotoS3.S3(
                    client: client,
                    region: Region(rawValue: "us-east-1")
                )
    }
    
    deinit {
        try? s3.client.syncShutdown()
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    func uploadImage(_ image: UIImage, rxNumber: String, scanType: ImageScanType) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw S3Error.imageConversionFailed
        }
        
        let s3Path = getS3Path(for: scanType)
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "rx_\(rxNumber)_\(timestamp).jpg"
        let key = s3Path + filename
        
        print("🚀 Starting S3 upload for: \(key)")
        
        // Create byte buffer from image data
        var buffer = ByteBufferAllocator().buffer(capacity: imageData.count)
        buffer.writeBytes(imageData)
        
        let putObjectRequest = S3.PutObjectRequest(
            acl: .private,
            body: .init(buffer: buffer),  // Changed: Use ByteBuffer directly
            bucket: bucketName,
            contentLength: Int64(imageData.count),
            contentType: "image/jpeg",
            key: key
        )
        
        do {
            print("\n=== S3 Upload Details ===")
            print("📁 Bucket: \(bucketName)")
            print("📄 File: \(key)")
            print("📦 Size: \(imageData.count) bytes")
            
            _ = try await s3.putObject(putObjectRequest)
            let imageUrl = "s3://\(bucketName)/\(key)"
            print("✅ Image uploaded successfully: \(imageUrl)")
            return imageUrl
        } catch {
            print("❌ Failed to upload image: \(error)")
            throw S3Error.uploadFailed(error)
        }
    }
    
    private func getS3Path(for scanType: ImageScanType) -> String {
        switch scanType {
        case .largeLabel:
            return S3Path.largeLabel
        case .coa:
            return S3Path.coa
        case .vial:
            return S3Path.vial
        }
    }
}
