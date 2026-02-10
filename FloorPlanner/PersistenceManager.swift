//
//  PersistenceManager.swift
//  FloorPlanner
//
//  Handles saving and loading projects using Core Data + CloudKit
//

import Foundation
import CoreData
import Combine

class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let stack = CoreDataStack.shared
    
    // Sync status publishing
    @Published var syncStatus: String = "Up to date"
    
    private init() {
        setupSyncMonitoring()
        migrateLegacyProjects()
    }

    // MARK: - Migration

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getProjectsDirectory() -> URL {
        let projectsDir = getDocumentsDirectory().appendingPathComponent("Projects")
        try? FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        return projectsDir
    }
    
    private func migrateLegacyProjects() {
        let projectsDir = getProjectsDirectory()
        guard let urls = try? FileManager.default.contentsOfDirectory(at: projectsDir, includingPropertiesForKeys: nil) else {
            return
        }

        let jsonFiles = urls.filter { $0.pathExtension == "json" }

        for url in jsonFiles {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let project = try decoder.decode(Project.self, from: data)

                // Save to Core Data
                try saveProject(project)

                // Move legacy file to backup or delete
                // For safety, let's rename extension to .migrated
                let destination = url.deletingPathExtension().appendingPathExtension("json.migrated")
                try? FileManager.default.removeItem(at: destination) // Remove if exists
                try FileManager.default.moveItem(at: url, to: destination)

                print("Migrated project: \(project.name)")
            } catch {
                print("Failed to migrate project at \(url): \(error)")
            }
        }
    }
    
    // MARK: - Save & Load
    
    func saveProject(_ project: Project) throws {
        let context = stack.viewContext
        
        try context.performAndWait {
            // Check if project exists
            let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)

            let results = try context.fetch(fetchRequest)
            let entity: ProjectEntity

            if let existing = results.first {
                entity = existing
            } else {
                entity = ProjectEntity(context: context)
                entity.id = project.id
                entity.createdAt = project.createdAt
            }

            // Update attributes
            entity.name = project.name
            entity.currency = project.currency
            entity.materialType = project.materialType.rawValue
            entity.wasteFactor = project.wasteFactor
            entity.modifiedAt = Date() // Update modified time on save

            // Update relationships
            updateRoomSettings(for: entity, from: project.roomSettings, context: context)
            updateStockItems(for: entity, from: project.stockItems, context: context)

            if let laminateSettings = project.laminateSettings {
                updateLaminateSettings(for: entity, from: laminateSettings, context: context)
            }

            if let tileSettings = project.tileSettings {
                updateTileSettings(for: entity, from: tileSettings, context: context)
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    func listProjects() throws -> [Project] {
        let context = stack.viewContext
        var projects: [Project] = []
        
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

            let entities = try context.fetch(fetchRequest)
            projects = entities.compactMap { convertToProject($0) }
        }

        return projects
    }
    
    func loadProject(id: UUID) throws -> Project? {
        let context = stack.viewContext
        var project: Project?

        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                project = convertToProject(entity)
            }
        }

        return project
    }
    
    func deleteProject(_ project: Project) throws {
        let context = stack.viewContext

        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", project.id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Helper Mapping Methods

    private func convertToProject(_ entity: ProjectEntity) -> Project? {
        guard let id = entity.id,
              let name = entity.name,
              let materialTypeString = entity.materialType,
              let materialType = MaterialType(rawValue: materialTypeString),
              let roomSettingsEntity = entity.roomSettings else {
            return nil
        }

        var project = Project(
            name: name,
            currency: entity.currency ?? "USD",
            materialType: materialType,
            roomSettings: convertRoomSettings(roomSettingsEntity),
            stockItems: convertStockItems(entity.stockItems),
            wasteFactor: entity.wasteFactor
        )
        
        project.id = id
        project.createdAt = entity.createdAt ?? Date()
        project.modifiedAt = entity.modifiedAt ?? Date()

        if let laminateEntity = entity.laminateSettings {
            project.laminateSettings = convertLaminateSettings(laminateEntity)
        }

        if let tileEntity = entity.tileSettings {
            project.tileSettings = convertTileSettings(tileEntity)
        }

        return project
    }
    
    private func convertRoomSettings(_ entity: RoomSettingsEntity) -> RoomSettings {
        let shape = RoomShape(rawValue: entity.shape ?? "Rectangular") ?? .rectangular
        let pattern = InstallationPattern(rawValue: entity.patternType ?? "Straight") ?? .straight

        var points: [RoomPoint] = []
        if let pointEntities = entity.polygonPoints?.array as? [RoomPointEntity] {
            // Assuming ordered set preserves order, or sort by orderIndex
            let sortedPoints = pointEntities.sorted { $0.orderIndex < $1.orderIndex }
            points = sortedPoints.map { RoomPoint(x: $0.x, y: $0.y) }
        }

        return RoomSettings(
            lengthMm: entity.lengthMm,
            widthMm: entity.widthMm,
            expansionGapMm: entity.expansionGapMm,
            shape: shape,
            polygonPoints: points,
            patternType: pattern,
            angleDegrees: entity.angleDegrees
        )
    }

    private func convertStockItems(_ set: NSSet?) -> [StockItem] {
        guard let set = set as? Set<StockItemEntity> else { return [] }
        return set.map { entity in
            var item = StockItem(
                lengthMm: entity.lengthMm,
                widthMm: entity.widthMm,
                quantity: Int(entity.quantity)
            )
            item.id = entity.id ?? UUID()
            item.pricePerUnit = entity.pricePerUnit > 0 ? entity.pricePerUnit : nil
            return item
        }.sorted { $0.lengthMm > $1.lengthMm }
    }

    private func convertLaminateSettings(_ entity: LaminateSettingsEntity) -> LaminateSettings {
        return LaminateSettings(
            minStaggerMm: entity.minStaggerMm,
            minOffcutLengthMm: entity.minOffcutLengthMm,
            plankDirection: LaminateSettings.PlankDirection(rawValue: entity.plankDirection ?? "Along Length") ?? .alongLength,
            defaultPlankLengthMm: entity.defaultPlankLengthMm,
            defaultPlankWidthMm: entity.defaultPlankWidthMm,
            defaultPricePerPlank: entity.defaultPricePerPlank > 0 ? entity.defaultPricePerPlank : nil
        )
    }

    private func convertTileSettings(_ entity: TileSettingsEntity) -> TileSettings {
        return TileSettings(
            tileSizeMm: entity.tileSizeMm,
            pattern: TileSettings.TilePattern(rawValue: entity.pattern ?? "Straight Grid") ?? .straight,
            orientation: TileSettings.TileOrientation(rawValue: entity.orientation ?? "Monolithic") ?? .monolithic,
            reuseEdgeOffcuts: entity.reuseEdgeOffcuts,
            tilesPerBox: entity.tilesPerBox > 0 ? Int(entity.tilesPerBox) : nil,
            defaultPricePerTile: entity.defaultPricePerTile > 0 ? entity.defaultPricePerTile : nil
        )
    }

    // MARK: - Update Helpers

    private func updateRoomSettings(for projectEntity: ProjectEntity, from settings: RoomSettings, context: NSManagedObjectContext) {
        let roomEntity = projectEntity.roomSettings ?? RoomSettingsEntity(context: context)
        roomEntity.project = projectEntity

        roomEntity.shape = settings.shape.rawValue
        roomEntity.lengthMm = settings.lengthMm
        roomEntity.widthMm = settings.widthMm
        roomEntity.expansionGapMm = settings.expansionGapMm
        roomEntity.patternType = settings.patternType.rawValue
        roomEntity.angleDegrees = settings.angleDegrees

        // Recreate polygon points
        if let existingPoints = roomEntity.polygonPoints {
            roomEntity.removeFromPolygonPoints(existingPoints)
        }

        for (index, point) in settings.polygonPoints.enumerated() {
            let pointEntity = RoomPointEntity(context: context)
            pointEntity.id = point.id
            pointEntity.x = point.x
            pointEntity.y = point.y
            pointEntity.orderIndex = Int64(index)
            roomEntity.addToPolygonPoints(pointEntity)
        }
    }

    private func updateStockItems(for projectEntity: ProjectEntity, from items: [StockItem], context: NSManagedObjectContext) {
        // Simple strategy: delete all and recreate
        if let existingItems = projectEntity.stockItems {
            projectEntity.removeFromStockItems(existingItems)
        }

        for item in items {
            let itemEntity = StockItemEntity(context: context)
            itemEntity.id = item.id
            itemEntity.lengthMm = item.lengthMm
            itemEntity.widthMm = item.widthMm
            itemEntity.quantity = Int64(item.quantity)
            itemEntity.pricePerUnit = item.pricePerUnit ?? 0
            projectEntity.addToStockItems(itemEntity)
        }
    }

    private func updateLaminateSettings(for projectEntity: ProjectEntity, from settings: LaminateSettings, context: NSManagedObjectContext) {
        let entity = projectEntity.laminateSettings ?? LaminateSettingsEntity(context: context)
        entity.project = projectEntity

        entity.minStaggerMm = settings.minStaggerMm
        entity.minOffcutLengthMm = settings.minOffcutLengthMm
        entity.plankDirection = settings.plankDirection.rawValue
        entity.defaultPlankLengthMm = settings.defaultPlankLengthMm
        entity.defaultPlankWidthMm = settings.defaultPlankWidthMm
        entity.defaultPricePerPlank = settings.defaultPricePerPlank ?? 0
    }

    private func updateTileSettings(for projectEntity: ProjectEntity, from settings: TileSettings, context: NSManagedObjectContext) {
        let entity = projectEntity.tileSettings ?? TileSettingsEntity(context: context)
        entity.project = projectEntity

        entity.tileSizeMm = settings.tileSizeMm
        entity.pattern = settings.pattern.rawValue
        entity.orientation = settings.orientation.rawValue
        entity.reuseEdgeOffcuts = settings.reuseEdgeOffcuts
        entity.tilesPerBox = Int64(settings.tilesPerBox ?? 0)
        entity.defaultPricePerTile = settings.defaultPricePerTile ?? 0
    }

    // MARK: - Sync Status

    private func setupSyncMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processCloudKitNotification),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: stack.container
        )
    }

    @objc private func processCloudKitNotification(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        DispatchQueue.main.async {
            if let error = event.error {
                self.syncStatus = "Sync Error: \(error.localizedDescription)"
            } else if event.succeeded {
                self.syncStatus = "Up to date"
            } else {
                self.syncStatus = "Syncing..."
            }
        }
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
