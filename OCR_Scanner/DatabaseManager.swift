import Foundation
import MySQLKit
import NIO
import NIOSSL

class DatabaseManager {
    static let shared = DatabaseManager()
    private var pools: EventLoopGroupConnectionPool<MySQLConnectionSource>?
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    private init() {
        do {
            try setupDatabase()
        } catch {
            print("❌ Database setup failed: \(error)")
        }
    }
    
    private func setupDatabase() throws {
//        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
//        tlsConfiguration.certificateVerification = .fullVerification
//        
//        // Path to Let's Encrypt certificates
//        let certPath = "/etc/letsencrypt/live/apps-dev.unithera.com/fullchain.pem"
//        
//        // Load the certificate and set as trust roots
//        let certs = try NIOSSLCertificate.fromPEMFile(certPath)
//        tlsConfiguration.trustRoots = .certificates(certs)
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
                // Allow self-signed certificates for development
                tlsConfiguration.certificateVerification = .none
                
                let configuration = MySQLConfiguration(
                    hostname: DatabaseConfig.host,
                    port: DatabaseConfig.port,
                    username: DatabaseConfig.user,
                    password: "",
                    database: DatabaseConfig.database,
                    tlsConfiguration: tlsConfiguration
                )
        
        pools = EventLoopGroupConnectionPool(
            source: MySQLConnectionSource(configuration: configuration),
            on: eventLoopGroup
        )
        
        print("✅ SSL Configuration loaded successfully")
    }
    
    
    func saveFormData(formData: FormData, imageUrls: [ScanType: String], currentUser: String) -> EventLoopFuture<Void> {
        guard let pools = pools else {
            return eventLoopGroup.next().makeFailedFuture(DatabaseError.notConnected)
        }
        
        return pools.withConnection { conn in
            let sql = conn.sql()
            let currentDateTime = Date()
            
            // Format the calibration date
            let formattedDate = self.formatDate(formData.calibrationDate)
            let dateTimeParts = formattedDate.split(separator: " ")
            let dateOnly = String(dateTimeParts[0])
            let timeOnly = String(dateTimeParts[1])
            
            let volumeNumber = formData.Volume.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted)
                        .joined()
            print("🔍 SQL binding date value: \(formattedDate)")
            
            // First insert
            return sql.raw(
                """
                INSERT INTO vial (
                    Radiopharmaceutical,
                    rx_number,
                    patient_id,
                    actual_amount,
                    calibration_date,
                    lot_number,
                    entered_by,
                    entered_date_time,
                    ordered_amount,
                    Manufacturer,
                    volume,
                    radioactivity_concentration,
                    label_image_url,
                    coa_image_url,
                    vial_image_url,
                    new_label_image_url,
                    new_vial_image_url
                ) VALUES (
                    \(bind: formData.Radiopharmaceutical),
                    \(bind: Int(formData.rx) ?? 0),
                    \(bind: formData.patientID),
                    \(bind: formData.ActualAmount),
                    \(bind: formattedDate),
                    \(bind: formData.lotNumber),
                    \(bind: currentUser),
                    \(bind: currentDateTime),
                    \(bind: formData.OrderedAmount),
                    \(bind: formData.Manufacturer),
                    \(bind: formData.Volume),
                    \(bind: formData.radioactivityConcentration),
                    \(bind: imageUrls[.largeLabel] ?? ""),
                    \(bind: imageUrls[.coa] ?? ""),
                    \(bind: imageUrls[.vial] ?? ""),
                    \(bind: formData.newLabelImageUrl ?? ""),    
                    \(bind: formData.newVialImageUrl ?? "") 
                )
                """
            ).run().flatMap { _ in
                // Second insert
                return sql.raw(
                    """
                    INSERT INTO dos_details (
                        patientId,
                        study_name,
                        dateCalibration,
                        timeCalibration,
                        rac,
                        manufacturer,
                        rx_batch,
                        lotBatch,
                        volume,
                        DOS
                    ) VALUES (
                        \(bind: formData.patientID),
                        \(bind: formData.Radiopharmaceutical),
                        \(bind: dateOnly),
                        \(bind: timeOnly),
                        \(bind: formData.radioactivityConcentration),
                        \(bind: formData.Manufacturer),
                        \(bind: Int(formData.rx) ?? 0),
                        \(bind: formData.lotNumber),
                        \(bind: volumeNumber),
                        '2025-03-27'
                    )
                    """
                ).run()
            }
        }
    }
    private func formatDate(_ dateString: String) -> String {
        print("📅 Original date string: \(dateString)")  // e.g., "05Feb2025 10:30 ET"
        
        // Split into components
        let components = dateString.split(separator: " ")
        guard components.count >= 2 else {
            print("❌ Failed to split date string")
            return dateString
        }
        
        let dateComponent = String(components[0])  // "05Feb2025"
        let timeComponent = String(components[1])  // "10:30"
        
        print("📍 Extracted components:")
        print("   Date: \(dateComponent)")
        print("   Time: \(timeComponent)")
        
        // Extract day, month, year
        let day = String(dateComponent.prefix(2))
        let month = String(dateComponent.dropFirst(2).prefix(3))
        let year = String(dateComponent.suffix(4))
        
        print("📊 Parsed date components:")
        print("   Day: \(day)")
        print("   Month: \(month)")
        print("   Year: \(year)")
        
        // Convert month name to number
        let monthNumber: String
        switch month.lowercased() {
        case "jan": monthNumber = "01"
        case "feb": monthNumber = "02"
        case "mar": monthNumber = "03"
        case "apr": monthNumber = "04"
        case "may": monthNumber = "05"
        case "jun": monthNumber = "06"
        case "jul": monthNumber = "07"
        case "aug": monthNumber = "08"
        case "sep": monthNumber = "09"
        case "oct": monthNumber = "10"
        case "nov": monthNumber = "11"
        case "dec": monthNumber = "12"
        default:
            print("⚠️ Unknown month: \(month)")
            monthNumber = "01"
        }
        
        // Format as YYYY-MM-DD HH:MM:SS
        let formattedDateTime = "\(year)-\(monthNumber)-\(day) \(timeComponent):00"
        print("✅ Final formatted datetime: \(formattedDateTime)")
        
        return formattedDateTime
    }
}

enum DatabaseError: Error {
    case notConnected
    case insertFailed
    case setupFailed
}
