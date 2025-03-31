namespace de.marianzeis.materialbomgraph;
using { cuid, managed } from '@sap/cds/common';


@odata.draft.enabled
@assert.unique: { materialId: [materialId] }
entity Material : cuid, managed {
  materialId: String(20) @mandatory;
  materialDescription: String(100);
  materialType: String(15);
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
 * Refactoring for BOM Hierarchy Resolution
 *
 * This approach uses iterative CDS views to resolve hierarchical relationships in the BOM structure.
 * It is designed to work with SQLite (doesnt support Hierachies like HANA does) 
 * and SAP CAP CDS, avoiding JavaScript logic and database-specific recursion.
 *
 * Key Steps:
 * 1. Base view (`Levels`) extracts direct parent-child relationships.
 * 2. Iterative views (`Level1`, `Level2`, etc.) expand the hierarchy step-by-step.
 * 3. Flattened hierarchy (`ExplodedHierarchy`) combines all levels using UNION ALL for OData exposure.
 *
 * This solution provides a clean structure for UI5 OData model binding to visualize BOM hierarchies.
 */

/**
 * Base view for extracting direct parent-child relationships from MaterialBOM.
 */
view Levels as
  select from MaterialBOM {
    key parentMaterial.materialId as fromMaterialId,
    key childMaterial.materialId  as toMaterialId,
        quantity,
        uom,
        relationshipType.code     as relationshipTypeCode,
        relationshipType.name     as relationshipTypeName
  };

/**
 * First level of hierarchy, showing direct relationships.
 */
view Level1 as
  select from Material
  left outer join Levels
    on Levels.fromMaterialId = Material.materialId
  {
    key Material.materialId as root,
    key Material.materialId as fromMaterialId,
    key toMaterialId,
        quantity,
        uom,
        relationshipTypeCode,
        relationshipTypeName
  };

/**
 *  Second level of hierarchy, expanding relationships further.
 */
view Level2 as
  select from Levels
  join Level1
    on Levels.fromMaterialId = Level1.toMaterialId
  {
    key Level1.root as root,
    key Levels.fromMaterialId,
    key Levels.toMaterialId,
        Levels.quantity,
        Levels.uom,
        Levels.relationshipTypeCode,
        Levels.relationshipTypeName
  };

/**
 * Third level of hierarchy, expanding relationships further.
 */
view Level3 as
  select from Levels
  join Level2
    on Levels.fromMaterialId = Level2.toMaterialId
  {
    key Level2.root as root,
    key Levels.fromMaterialId,
    key Levels.toMaterialId,
        Levels.quantity,
        Levels.uom,
        Levels.relationshipTypeCode,
        Levels.relationshipTypeName
  };

/**
 *  Combines all levels into a flattened hierarchy using UNION ALL.
 */
view ExplodeLevels as
    select from Level1 {
      key root,
      key fromMaterialId,
      key toMaterialId,
          quantity,
          uom,
          relationshipTypeCode,
          relationshipTypeName
    }
  union all
    select from Level2 {
      key root,
      key fromMaterialId,
      key toMaterialId,
          quantity,
          uom,
          relationshipTypeCode,
          relationshipTypeName
    }
  union all
    select from Level3 {
      key root,
      key fromMaterialId,
      key toMaterialId,
          quantity,
          uom,
          relationshipTypeCode,
          relationshipTypeName
    };

/**
 * Represents edges (relationships) between materials for visualization.
 */
@cds.autoexpose
view Lines as
  select from ExplodeLevels {
    key ExplodeLevels.root                                                 as root,
    key ExplodeLevels.fromMaterialId                                       as fromKey,
    key ExplodeLevels.toMaterialId                                         as toKey,
        'Quantity: ' || ExplodeLevels.quantity || ' ' || ExplodeLevels.uom as description : String,
        ExplodeLevels.relationshipTypeName                                 as title
  }
  where
        ExplodeLevels.fromMaterialId is not null                                             
    and ExplodeLevels.toMaterialId   is not null;

/**
 * Represents individual materials (nodes) in the hierarchy.
 */
view Nodes as
  select from Material
  join ExplodeLevels
    on ExplodeLevels.toMaterialId   = Material.materialId
    or ExplodeLevels.fromMaterialId = Material.materialId
  {
    key ExplodeLevels.root           as root,
    key Material.materialId          as nodeKey,
        Material.materialId          as materialId,
        Material.ID                  as ID,
        Material.materialType,
        Material.materialDescription as title,
        Material.materialType        as status
  }
  group by
    ExplodeLevels.root,
    Material.materialId,
    Material.ID,
    Material.materialDescription,
    Material.materialType;

/**
 *  Converts material properties transposing into key-value pairs  
 */
@cds.autoexpose
view NodeAttributes as
    select from Nodes {
      key root          as root,
      key nodeKey       as nodeKey,
      key 'Material ID' as label   : String,
          materialId    as value   : String,
    }
  union all
    select from Nodes {
      key root            as root,
      key nodeKey         as nodeKey,
      key 'Material Type' as label : String,
          materialType    as value : String,
    }

/**
 * Combines nodes with their attributes.
 */
@cds.autoexpose
view NodesWithAttributes as
  select from Nodes {
    *,
    attributes : Association to many NodeAttributes on attributes.root    = $self.root
                 and                                   attributes.nodeKey = $self.nodeKey
  }

/**
 * Adds associations to expose hierarchical data via OData.
 */
extend entity Material {
  nodes : Association to many NodesWithAttributes
            on nodes.root = $self.materialId;
  lines : Association to many Lines
            on lines.root = $self.materialId;
}