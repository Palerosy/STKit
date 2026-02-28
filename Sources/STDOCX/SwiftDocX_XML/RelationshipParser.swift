import Foundation

/// Parsed relationship entry from document.xml.rels
struct DocumentRelationship {
    let id: String
    let type: String
    let target: String
}

/// Parses word/_rels/document.xml.rels to extract relationship mappings
class RelationshipParser: NSObject, XMLParserDelegate {

    private var relationships: [String: DocumentRelationship] = [:]

    /// Parse relationships XML data and return a dictionary keyed by rId
    func parse(_ xmlData: Data) -> [String: DocumentRelationship] {
        relationships = [:]
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.parse()
        return relationships
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let localName = elementName.contains(":") ?
            String(elementName[elementName.index(after: elementName.lastIndex(of: ":")!)...]) :
            elementName

        if localName == "Relationship" {
            guard let id = attributeDict["Id"],
                  let type = attributeDict["Type"],
                  let target = attributeDict["Target"] else { return }

            relationships[id] = DocumentRelationship(id: id, type: type, target: target)
        }
    }
}
