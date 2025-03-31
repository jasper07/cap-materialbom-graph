using {de.marianzeis.materialbomgraph as MaterialSchema} from '../db/schema.cds';

service MaterialGraph {
    entity Material         as projection on MaterialSchema.Material;
    entity MaterialBOM      as projection on MaterialSchema.MaterialBOM;
    entity RelationshipType as projection on MaterialSchema.RelationshipType;
}
