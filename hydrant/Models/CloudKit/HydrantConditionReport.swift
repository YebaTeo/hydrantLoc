//
//  HydrantConditionReport.swift
//  hydrant
//
//  A field report on a hydrant's condition. Append-only: every report is its own
//  record, nothing is overwritten, so there are no write conflicts (design §06).
//  A `sesaat` report expires 24h after it is filed and is filtered at read time; a
//  `permanen` report stays until resolved (verification queue is out of demo scope).
//

import CloudKit
import Foundation

// How lasting the reported condition is. Drives the treatment rules in design §02.
enum ConditionLevel: String, CaseIterable, Identifiable {
    case sesaat      // temporary: blocked access, road works — auto-expires in 24h
    case permanen    // lasting: dead valve, wrong coupling — a standing warning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sesaat: return "Sementara"
        case .permanen: return "Permanen"
        }
    }

    var explanation: String {
        switch self {
        case .sesaat: return "Kedaluwarsa otomatis 24 jam. Contoh: akses terhalang, jalan ditutup."
        case .permanen: return "Peringatan tetap sampai diverifikasi. Contoh: mati, kopling tidak cocok."
        }
    }
}

// The observed condition. `berfungsi` is the recovery path — the way a hydrant
// wrongly recorded as broken gets restored (design §02).
enum HydrantCondition: String, CaseIterable, Identifiable {
    case berfungsi = "berfungsi"
    case mati = "mati"
    case tekananLemah = "tekanan_lemah"
    case aksesTerhalang = "akses_terhalang"
    case koplingTidakCocok = "kopling_tidak_cocok"
    case tidakDitemukan = "tidak_ditemukan"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .berfungsi: return "Berfungsi"
        case .mati: return "Mati / Tidak Keluar Air"
        case .tekananLemah: return "Tekanan Lemah"
        case .aksesTerhalang: return "Akses Terhalang"
        case .koplingTidakCocok: return "Kopling Tidak Cocok"
        case .tidakDitemukan: return "Tidak Ditemukan"
        }
    }

    var systemImage: String {
        switch self {
        case .berfungsi: return "checkmark.circle.fill"
        case .mati: return "drop.triangle.fill"
        case .tekananLemah: return "gauge.with.dots.needle.33percent"
        case .aksesTerhalang: return "exclamationmark.triangle.fill"
        case .koplingTidakCocok: return "wrench.adjustable.fill"
        case .tidakDitemukan: return "questionmark.circle.fill"
        }
    }

    // A positive report (recovery) vs. a problem that should warn other units.
    var isProblem: Bool { self != .berfungsi }
}

struct HydrantConditionReport: Identifiable, Equatable {
    let id: UUID
    let hidranID: Int
    let incidentID: UUID?
    let reportedByUnit: String
    let time: Date
    let level: ConditionLevel
    let condition: HydrantCondition
    let note: String?
    // Only set for `sesaat` reports: time + 24h. nil means no expiry.
    let expiresAt: Date?

    init(
        id: UUID = UUID(),
        hidranID: Int,
        incidentID: UUID? = nil,
        reportedByUnit: String,
        time: Date = .now,
        level: ConditionLevel,
        condition: HydrantCondition,
        note: String? = nil
    ) {
        self.id = id
        self.hidranID = hidranID
        self.incidentID = incidentID
        self.reportedByUnit = reportedByUnit
        self.time = time
        self.level = level
        self.condition = condition
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.expiresAt = level == .sesaat ? time.addingTimeInterval(24 * 60 * 60) : nil
    }

    func isActive(now: Date = .now) -> Bool {
        guard let expiresAt else { return true }   // permanen never expires here
        return now < expiresAt
    }
}

// MARK: - CKRecord mapping

extension HydrantConditionReport {
    // Record name derived from the report UUID (device-generated at report time),
    // so an offline replay is idempotent — the same report never lands twice.
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: "laporan-\(id.uuidString)")
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.ConditionReport.type, recordID: recordID)
        record[CloudKitSchema.ConditionReport.hidranID] = hidranID as CKRecordValue
        record[CloudKitSchema.ConditionReport.reportedBy] = reportedByUnit as CKRecordValue
        record[CloudKitSchema.ConditionReport.time] = time as CKRecordValue
        record[CloudKitSchema.ConditionReport.level] = level.rawValue as CKRecordValue
        record[CloudKitSchema.ConditionReport.condition] = condition.rawValue as CKRecordValue
        if let incidentID {
            record[CloudKitSchema.ConditionReport.insidenID] = incidentID.uuidString as CKRecordValue
        }
        if let note {
            record[CloudKitSchema.ConditionReport.note] = note as CKRecordValue
        }
        if let expiresAt {
            record[CloudKitSchema.ConditionReport.expiresAt] = expiresAt as CKRecordValue
        }
        return record
    }

    init?(record: CKRecord) {
        guard
            record.recordType == CloudKitSchema.ConditionReport.type,
            let hidranID = record[CloudKitSchema.ConditionReport.hidranID] as? Int,
            let unit = record[CloudKitSchema.ConditionReport.reportedBy] as? String,
            let time = record[CloudKitSchema.ConditionReport.time] as? Date,
            let levelRaw = record[CloudKitSchema.ConditionReport.level] as? String,
            let level = ConditionLevel(rawValue: levelRaw),
            let conditionRaw = record[CloudKitSchema.ConditionReport.condition] as? String,
            let condition = HydrantCondition(rawValue: conditionRaw),
            let uuid = UUID(uuidString: record.recordID.recordName
                .replacingOccurrences(of: "laporan-", with: ""))
        else {
            return nil
        }
        let incidentID = (record[CloudKitSchema.ConditionReport.insidenID] as? String)
            .flatMap(UUID.init)
        self.init(
            id: uuid,
            hidranID: hidranID,
            incidentID: incidentID,
            reportedByUnit: unit,
            time: time,
            level: level,
            condition: condition,
            note: record[CloudKitSchema.ConditionReport.note] as? String
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
