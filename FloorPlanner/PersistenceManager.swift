//
//  PersistenceManager.swift
//  FloorPlanner
//
//  Handles saving and loading projects as JSON
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private init() {}
    
    // MARK: - File Management
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getProjectsDirectory() -> URL {
        let projectsDir = getDocumentsDirectory().appendingPathComponent("Projects")
        try? FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        return projectsDir
    }
    
    func getProjectURL(for project: Project) -> URL {
        let filename = "\(project.id.uuidString).json"
        return getProjectsDirectory().appendingPathComponent(filename)
    }
    
    // MARK: - Save & Load
    
    func saveProject(_ project: Project) throws {
        let url = getProjectURL(for: project)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
    }
    
    func loadProject(from url: URL) throws -> Project {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Project.self, from: data)
    }
    
    func loadProject(id: UUID) throws -> Project {
        let filename = "\(id.uuidString).json"
        let url = getProjectsDirectory().appendingPathComponent(filename)
        return try loadProject(from: url)
    }
    
    func listProjects() throws -> [Project] {
        let projectsDir = getProjectsDirectory()
        let urls = try FileManager.default.contentsOfDirectory(
            at: projectsDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        return urls.compactMap { url in
            try? loadProject(from: url)
        }.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    func deleteProject(_ project: Project) throws {
        let url = getProjectURL(for: project)
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Export
    
    func exportPlacementCSV(result: LayoutResult) -> String {
        var csv = "Label,X(mm),Y(mm),Length(mm),Width(mm),Source,Status,Rotation\n"
        
        for piece in result.placedPieces {
            csv += "\(piece.label),"
            csv += "\(piece.x),"
            csv += "\(piece.y),"
            csv += "\(piece.lengthMm),"
            csv += "\(piece.widthMm),"
            csv += "\(piece.source.rawValue),"
            csv += "\(piece.status.rawValue),"
            csv += "\(piece.rotation)\n"
        }
        
        return csv
    }
    
    func exportCutListCSV(result: LayoutResult, materialType: MaterialType) -> String {
        if materialType == .laminate {
            var csv = "Row,CutType,FromLength(mm),CutTo(mm),Offcut(mm),Width(mm)\n"
            
            for cut in result.cutRecords {
                csv += "\(cut.row ?? 0),"
                csv += "\(cut.cutType?.rawValue ?? ""),"
                csv += "\(cut.fromLengthMm ?? 0),"
                csv += "\(cut.cutToMm ?? 0),"
                csv += "\(cut.offcutLengthMm ?? 0),"
                csv += "\(cut.widthMm ?? 0)\n"
            }
            
            return csv
        } else {
            var csv = "EdgeCutCount,Dimensions\n"
            
            for cut in result.cutRecords {
                csv += "\(cut.edgeCutCount ?? 0),"
                csv += "\"\(cut.cutDimensionsMm ?? "")\"\n"
            }
            
            return csv
        }
    }
    
    func exportRemainingInventoryCSV(result: LayoutResult) -> String {
        var csv = "Length(mm),Width(mm),Source\n"
        
        for piece in result.remainingPieces {
            csv += "\(piece.lengthMm),"
            csv += "\(piece.widthMm),"
            csv += "\(piece.source.rawValue)\n"
        }
        
        return csv
    }
    
    func exportPurchaseListCSV(result: LayoutResult) -> String {
        var csv = "UnitLength(mm),UnitWidth(mm),Quantity,Packs\n"
        
        for suggestion in result.purchaseSuggestions {
            csv += "\(suggestion.unitLengthMm),"
            csv += "\(suggestion.unitWidthMm),"
            csv += "\(suggestion.quantityNeeded),"
            csv += "\(suggestion.packsNeeded ?? 0)\n"
        }
        
        return csv
    }
}
