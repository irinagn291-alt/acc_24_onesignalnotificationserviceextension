import CoreData
import Foundation

final class DayListRepository: DayListStoring {
    private let stack: PersistenceControllerPayload

    init(stack: PersistenceControllerPayload) {
        self.stack = stack
    }

    private func normalizedDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func summaries() async throws -> [DayListSummary] {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let boardFR = DayListEntity.fetchRequest()
            boardFR.sortDescriptors = [NSSortDescriptor(keyPath: \DayListEntity.dayStart, ascending: false)]
            let boards = try ctx.fetch(boardFR)
            return try boards.map { board in
                let cFR = DayListItemEntity.fetchRequest()
                cFR.predicate = NSPredicate(format: "listUUID == %@", board.listUUID as CVarArg)
                let n = try ctx.count(for: cFR)
                return DayListSummary(listUUID: board.listUUID, dayStart: board.dayStart, itemCount: n)
            }
        }
    }

    func items(dayStart: Date) async throws -> [DayListItemRow] {
        let ctx = stack.viewContext
        let start = normalizedDay(dayStart)
        return try await ctx.perform {
            let bFR = DayListEntity.fetchRequest()
            bFR.predicate = NSPredicate(format: "dayStart == %@", start as CVarArg)
            bFR.fetchLimit = 1
            guard let board = try ctx.fetch(bFR).first else { return [] }
            let iFR = DayListItemEntity.fetchRequest()
            iFR.predicate = NSPredicate(format: "listUUID == %@", board.listUUID as CVarArg)
            iFR.sortDescriptors = [NSSortDescriptor(keyPath: \DayListItemEntity.sortIndex, ascending: true)]
            return try ctx.fetch(iFR).map {
                DayListItemRow(
                    id: $0.itemUUID,
                    barcode: $0.barcode,
                    name: $0.name,
                    brand: $0.brand,
                    imageUrl: $0.imageURLString,
                    nutriScore: $0.nutriScore,
                    addedAt: $0.addedAt
                )
            }
        }
    }

    func addProduct(dayStart: Date, product: Product) async throws {
        let ctx = stack.viewContext
        let start = normalizedDay(dayStart)
        try await ctx.perform {
            let bFR = DayListEntity.fetchRequest()
            bFR.predicate = NSPredicate(format: "dayStart == %@", start as CVarArg)
            bFR.fetchLimit = 1
            let listId: UUID
            if let board = try ctx.fetch(bFR).first {
                listId = board.listUUID
            } else {
                let board = DayListEntity(context: ctx)
                listId = UUID()
                board.listUUID = listId
                board.dayStart = start
            }
            let countFR = DayListItemEntity.fetchRequest()
            countFR.predicate = NSPredicate(format: "listUUID == %@", listId as CVarArg)
            let nextIndex = Int32(try ctx.count(for: countFR))
            let dupFR = DayListItemEntity.fetchRequest()
            dupFR.predicate = NSPredicate(format: "listUUID == %@ AND barcode == %@", listId as CVarArg, product.barcode)
            dupFR.fetchLimit = 1
            if try ctx.fetch(dupFR).first != nil {
                return
            }
            let row = DayListItemEntity(context: ctx)
            row.itemUUID = UUID()
            row.listUUID = listId
            row.sortIndex = nextIndex
            row.barcode = product.barcode
            row.name = product.name
            row.brand = product.brand
            row.imageURLString = product.imageUrl
            row.nutriScore = product.nutriScore
            row.addedAt = Date()
            try ctx.save()
        }
    }

    func removeItem(itemId: UUID) async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = DayListItemEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "itemUUID == %@", itemId as CVarArg)
            fr.fetchLimit = 1
            if let o = try ctx.fetch(fr).first {
                ctx.delete(o)
            }
            if ctx.hasChanges { try ctx.save() }
        }
    }
}
