namespace de.marianzeis.materialbomgraph;
using { cuid, managed } from '@sap/cds/common';


@odata.draft.enabled
@assert.unique: { materialId: [materialId] }
entity Material : cuid, managed {
  materialId: String(20) @mandatory;
  materialDescription: String(100);
  materialType: String(15);
  graph : Composition of one GraphNetwork on graph.root = $self;
  bomParent: Composition of many MaterialBOM on bomParent.parentMaterial = $self;
  bomChild: Composition of many MaterialBOM on bomChild.childMaterial = $self;
}


entity MaterialBOM : cuid, managed {
  parentMaterial: Association to Material;  // e.g., higher-level component
  childMaterial: Association to Material;   // e.g., sub-component, raw, or packaging
  quantity: Decimal(13,3);                 // e.g., "2.5 childMaterial units"
  uom: String(10);                         // e.g., "KG", "L", "PC"
  relationshipType: Association to one RelationshipType;
}

/**
 * Relationship types might be things like 'Component', 'Packaging', or 'Raw', giving more detail 
 * on how the parent material relates to the child's position or function in the BOM.
 */
@assert.unique: { code: [code] }
@odata.draft.enabled
entity RelationshipType : cuid, managed {
  code: String(10) @mandatory;
  name: String(50);
}

/**
 * Pseudo-entity used to return a graphical representation of a Material's hierarchy.
 * We'll populate 'nodes' and 'lines' at runtime to render a visual graph in a Fiori app.
 * The 'root' association is used to link this network structure back to the original Material.
 * IT is a composition of the Material entity to be able to go to edit mode in object page.
 */
entity GraphNetwork {
  key ID: UUID;
  root: Association to Material;
  nodes: LargeString;  // JSON string of nodes
  lines: LargeString;  // JSON string of lines
  groups: LargeString; // JSON string of groups (optional)
}