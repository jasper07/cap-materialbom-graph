const cds = require('@sap/cds');

module.exports = cds.service.impl(function () {
  const { Material, MaterialBOM, RelationshipType } = this.entities;

  /**
   * Overwrite READ for the pseudo‐entity "GraphNetwork"
   * We'll accept a Material's ID as the "root" in the request path:
   * e.g., GET /GraphNetwork(ID=<material-uuid>)
   * Then we'll recursively traverse the Bill of Materials (BOM) to build a node graph.
   * 
   * The main idea here is to dynamically build a network-like structure of nodes and lines
   * which represent your material hierarchy.
   */
  this.on('READ', 'GraphNetwork', async (req) => {
    // 1) Extract the root Material's ID from the request parameters.
    // The ID is used to know where the traversal (BOM exploration) starts.
    const rootMaterialID = req.params[0]?.ID;
    if (!rootMaterialID) {
      // If no root ID is found, return an empty array.
      // This means no material is specified, so there's no graph to build.
      return [];
    }

    // 2) We'll perform a Breadth-First Search (BFS) or Depth-First Search (DFS) to gather child materials.
    // visited: keeps track of visited nodes to avoid loops or repeated references
    // nodesMap: stores each node object with a unique key
    // linesArr: stores relationships (edges) between materials
    const visited = new Set();
    const nodesMap = new Map();
    const linesArr = [];

    /**
     * Recursively traverse the BOM from a given parent material.
     * We'll track path segments to ensure we can differentiate multiple appearances of the same material
     * (but still prevent infinite loops).
     * 
     * parentID: The current material ID we're examining
     * path: A string built up to ensure uniqueness when a material might appear more than once in different branches
     */
    async function traverseBOM(parentID, path = '') {
      // Mark each entry with a unique visited key (material + path).
      const visitedKey = `${parentID}_${path}`;
      if (visited.has(visitedKey)) return;
      visited.add(visitedKey);

      // Fetch the parent material record.
      // This ensures we get details like materialId, description, etc.
      const parentMat = await SELECT.one.from(Material).where({ ID: parentID });
      if (!parentMat) return;

      // Generate a "nodeKey" to identify the material in our graph.
      // The path helps ensure uniqueness when the same material is encountered via different routes.
      const nodeKey = `${parentMat.materialId}_${path}`;

      // Create or update our node in the nodeMap.
      // This node object is what the frontend reads to display each material box (Node).
      nodesMap.set(nodeKey, {
        key: nodeKey,
        title: parentMat.materialDescription,
        // You can update 'icon' to be an SAP icon as desired, referencing e.g. 'sap-icon://cart'.
        icon: parentMat.materialType,
        // 'status' here ties to SAP UI statuses, which can be color-coded in the graph.
        status: parentMat.materialType,
        attributes: [
          { label: 'Material ID', value: parentMat.materialId },
          { label: 'Material Type', value: parentMat.materialType }
        ],
        customData: {
          materialId: parentMat.materialId,
          materialType: parentMat.materialType,
          material_ID: parentMat.ID
        }
      });

      // Retrieve the children (BOM entries) for this parent.
      // This effectively finds all sub-components of the current material.
      const childBOMs = await SELECT.from(MaterialBOM).where({ parentMaterial_ID: parentID });
      for (const row of childBOMs) {
        const childMat = await SELECT.one.from(Material).where({ ID: row.childMaterial_ID });
        if (childMat) {
          // Build a nodeKey for the child.
          // Notice how we append the parent's materialId to the path to keep it unique.
          const childNodeKey = `${childMat.materialId}_${path}${parentMat.materialId}_`;

          // Get the relationship type for the current BOM entry.
          const relationshipType = await SELECT.one.from(RelationshipType).where({ ID: row.relationshipType_ID });

          // Add a line (edge) from parent to child in the graph.
          // The 'description' can store information like quantity and UOM for display on the edge.
          linesArr.push({
            from: nodeKey,
            to: childNodeKey,
            description: `Quantity: ${row.quantity} ${row.uom}`,
            title: relationshipType.name
          });

          // Recurse into the child material to find its BOM children.
          await traverseBOM(childMat.ID, `${path}${parentMat.materialId}_`);
        }
      }
    }

    // Start traversal from the root material.
    // This is the entry point, passing the user-specified root ID.
    await traverseBOM(rootMaterialID);

    // 3) Return exactly one record for GraphNetwork with the computed nodes and lines.
    // 'groups' can be used for additional grouping logic, if needed.
    return [
      {
        ID: '00000000-0000-0000-0000-000000000000', // Static ID for the pseudo-entity
        root_ID: rootMaterialID,
        nodes: JSON.stringify(Array.from(nodesMap.values())),
        lines: JSON.stringify(linesArr)
      }
    ];
  });
});