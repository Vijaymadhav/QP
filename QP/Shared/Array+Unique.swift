import Foundation

extension Array where Element: Identifiable, Element.ID: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element.ID>()
        var result: [Element] = []
        for element in self {
            if seen.insert(element.id).inserted {
                result.append(element)
            }
        }
        return result
    }
}
