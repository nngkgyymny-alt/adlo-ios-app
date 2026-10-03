import Foundation

// Mirrors adlo-portal's src/types/form.ts and StoredSubmission shape, and
// adlo-cross's src/api/portalTypes.ts — keep in sync with those.

enum FormFieldType: String, Codable {
    case text, name, date, address, phone, email, select, boolean, number, textarea
}

/// A form field's answer, or a conditional rule's comparison value — the
/// schema allows string, bool, or number here, so this can't be a plain
/// Swift type. Order matters for decoding: try Bool before Double before
/// String (a JSON string like "42" should stay a string, not become 42).
enum FormFieldValue: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case number(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.typeMismatch(
                FormFieldValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported form field value")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .bool(let b): try container.encode(b)
        case .number(let n): try container.encode(n)
        }
    }

    var stringValue: String {
        switch self {
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .number(let n):
            let isWholeAndRepresentable = n.isFinite
                && n.truncatingRemainder(dividingBy: 1) == 0
                && abs(n) < 1e15
            return isWholeAndRepresentable ? String(Int(n)) : String(n)
        }
    }
}

typealias FormData = [String: FormFieldValue]

struct ConditionalRule: Codable {
    let `if`: String
    let equals: FormFieldValue
}

func matchesConditional(_ rule: ConditionalRule?, _ data: FormData) -> Bool {
    guard let rule else { return true }
    return data[rule.`if`] == rule.equals
}

struct FormField: Codable, Identifiable {
    let id: String
    let label: String
    let type: FormFieldType
    let required: Bool?
    let hint: String?
    let options: [String]?
    let conditional: ConditionalRule?
}

struct FormSection: Codable, Identifiable {
    let id: String
    let title: String
    let hint: String?
    let conditional: ConditionalRule?
    let fields: [FormField]
}

struct FormSchema: Codable {
    let id: String
    let name: String
    let category: String
    let description: String
    let sections: [FormSection]
}

struct FormCategory: Codable, Identifiable {
    let id: String
    let label: String
    let icon: String
}

struct FieldCount: Codable {
    let total: Int
    let required: Int
}

struct FormListItem: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let fieldCount: FieldCount
}

struct FormsListResponse: Codable {
    let categories: [FormCategory]
    let forms: [FormListItem]
}

struct SubmissionSummary: Codable, Identifiable {
    let key: String
    let formId: String
    let formName: String
    let contactId: String?
    let submittedAt: String
    let clientName: String
    let clientEmail: String
    let syncedToLawmatics: Bool
    let submittedFinal: Bool

    var id: String { key }
}

struct SubmissionsListResponse: Codable {
    let submissions: [SubmissionSummary]
}

struct SubmissionDetail: Codable {
    let key: String
    let formId: String
    let formName: String
    let contactId: String?
    let language: String
    let clientType: String
    let submittedAt: String
    let data: FormData
    let lawmaticsContactId: String?
    let lawmaticsSyncedAt: String?
    let ownerEmail: String?
    let submittedFinal: Bool?
}

struct CreateSubmissionResponse: Codable {
    let key: String
    let formId: String
    let formName: String
}

struct SubmitSubmissionResponse: Codable {
    let ok: Bool
    let prospectId: String?
}
