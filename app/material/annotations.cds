using MaterialGraph as service from '../../srv/service';

// List Report Annotations
annotate service.Material with @(
    UI: {
        SelectionFields: [
            materialId,
            materialDescription,
            materialType
        ],
        LineItem: [
            {
                $Type: 'UI.DataField',
                Value: materialId,
                Label: 'Material ID'
            },
            {
                $Type: 'UI.DataField',
                Value: materialDescription,
                Label: 'Description'
            },
            {
                $Type: 'UI.DataField',
                Value: materialType,
                Label: 'Material Type'
            }
        ]
    }
);

// Object Page Annotations
annotate service.Material with @(
    UI: {
        HeaderInfo: {
            TypeName: 'Material',
            TypeNamePlural: 'Materials',
            Title: {
                $Type: 'UI.DataField',
                Value: materialId
            },
            Description: {
                $Type: 'UI.DataField',
                Value: materialDescription
            }
        },
        HeaderFacets: [
            {
                $Type: 'UI.ReferenceFacet',
                Target: '@UI.FieldGroup#MaterialDetails'
            }
        ],
        FieldGroup#MaterialDetails: {
            Data: [
                {
                    $Type: 'UI.DataField',
                    Value: materialType,
                    Label: 'Material Type'
                },
                {
                    $Type: 'UI.DataField',
                    Value: materialDescription,
                    Label: 'Description'
                }
            ]
        },
        Facets: [
            {
                $Type: 'UI.ReferenceFacet',
                ID: 'GeneralInformation',
                Label: 'General Information',
                Target: '@UI.FieldGroup#MaterialDetails'
            },
            {
                $Type: 'UI.ReferenceFacet',
                Label: 'Child BOMs',
                Target: 'bomParent/@UI.SelectionPresentationVariant#Child'
            },
            {
                $Type: 'UI.ReferenceFacet',
                Label: 'Parent BOMs',
                Target: 'bomChild/@UI.SelectionPresentationVariant#Parent'
            }
        ],
        Identification: [
            {
                Value: materialId
            }
        ]
    }
);

// BOM Table Annotations
annotate service.MaterialBOM with @(
    UI: {
        LineItem: [
            {
                $Type: 'UI.DataField',
                Value: parentMaterial.materialId,
                Label: 'Parent Material'
            },
            {
                $Type: 'UI.DataField',
                Value: childMaterial.materialId,
                Label: 'Child Material'
            },
            {
                $Type: 'UI.DataField',
                Value: quantity,
                Label: 'Quantity'
            },
            {
                $Type: 'UI.DataField',
                Value: uom,
                Label: 'Unit of Measure'
            },
            {
                $Type: 'UI.DataField',
                Value: relationshipType.name,
                Label: 'Relationship Type'
            }
        ]
    }
);

// Add additional annotations for Material
annotate service.Material with {
    // Property Titles
    materialId          @title: 'Material ID';
    materialDescription @title: 'Material Description';
    materialType        @title: 'Material Type';
}

// Enhanced MaterialBOM annotations
annotate service.MaterialBOM with {
    childMaterial    @title: 'Child Material';
    parentMaterial   @title: 'Parent Material';
    quantity         @title: 'Quantity';
    uom              @title: 'Unit of Measure';
    relationshipType @title: 'Relationship Type';

    // Value help for child material
    childMaterial @(Common.ValueList: {
        CollectionPath: 'Material',
        Parameters: [
            {
                $Type: 'Common.ValueListParameterInOut',
                LocalDataProperty: childMaterial_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'materialId'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'materialDescription'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'plant/plantName'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'brand/brandName'
            }
        ],
        SearchSupported: true,
        Label: 'Select Child Material'
    });

    // Text arrangements
    childMaterial    @Common.Text: childMaterial.materialId;
    childMaterial    @Common.TextArrangement: #TextOnly;
    parentMaterial   @Common.Text: parentMaterial.materialId;
    parentMaterial   @Common.TextArrangement: #TextOnly;

    // Value help for parent material
    parentMaterial @(Common.ValueList: {
        CollectionPath: 'Material',
        Parameters: [
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'materialId'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'materialDescription'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'plant/plantName'
            },
            {
                $Type: 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'brand/brandName'
            }
        ],
        SearchSupported: true,
        Label: 'Select Parent Material'
    });


    // Add ValueList for relationshipType
    relationshipType @(Common: {
        ValueListWithFixedValues: true,
        ValueList: {
            $Type: 'Common.ValueListType',
            CollectionPath: 'RelationshipType',
            Parameters: [
                {
                    $Type: 'Common.ValueListParameterOut',
                    LocalDataProperty: relationshipType_ID,
                    ValueListProperty: 'ID'
                },
                {
                    $Type: 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'code'
                },
                {
                    $Type: 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'name'
                }
            ],
            SearchSupported: true,
            Label: 'Relationship Types'
        }
    });

        // Text arrangement for relationshipType
    relationshipType @Common.Text: relationshipType.name;
    relationshipType @Common.TextArrangement: #TextOnly;
}

// Update MaterialBOM UI annotations
annotate service.MaterialBOM with @(
    UI: {
        SelectionPresentationVariant #Child: {
            SelectionVariant: {
                $Type: 'UI.SelectionVariantType'
            },
            PresentationVariant: {
                SortOrder: [{
                    Property: parentMaterial_ID,
                    Descending: false
                }],
                Visualizations: ['@UI.LineItem#Child']
            }
        },

        SelectionPresentationVariant #Parent: {
            SelectionVariant: {
                $Type: 'UI.SelectionVariantType'
            },
            PresentationVariant: {
                SortOrder: [{
                    Property: childMaterial_ID,
                    Descending: false
                }],
                Visualizations: ['@UI.LineItem#Parent']
            }
        },

        SelectionFields: [
            childMaterial_ID,
            relationshipType_ID
        ],

        LineItem #Parent: [
            {
                $Type: 'UI.DataField',
                Value: parentMaterial_ID,
                Label: 'Parent Material'
            },
            {
                $Type: 'UI.DataField',
                Value: childMaterial.materialDescription,
                Label: 'Description'
            },
            {
                $Type: 'UI.DataField',
                Value: quantity
            },
            {
                $Type: 'UI.DataField',
                Value: uom
            },
            {
                $Type: 'UI.DataField',
                Value: relationshipType_ID
            }
        ],

        LineItem #Child: [
            {
                $Type: 'UI.DataField',
                Value: childMaterial_ID,
                Label: 'Child Material'
            },
            {
                $Type: 'UI.DataField',
                Value: childMaterial.materialDescription,
                Label: 'Description'
            },
            {
                $Type: 'UI.DataField',
                Value: quantity
            },
            {
                $Type: 'UI.DataField',
                Value: uom
            },
            {
                $Type: 'UI.DataField',
                Value: relationshipType_ID
            }
        ],

        Facets: [
            {
                $Type: 'UI.ReferenceFacet',
                Label: 'General Information',
                Target: '@UI.FieldGroup#General'
            }
        ],

        FieldGroup #General: {
            $Type: 'UI.FieldGroupType',
            Data: [
                {
                    $Type: 'UI.DataField',
                    Value: childMaterial_ID,
                    Label: 'Child Material'
                },
                {
                    $Type: 'UI.DataField',
                    Value: childMaterial.materialDescription,
                    Label: 'Description'
                },
                {
                    $Type: 'UI.DataField',
                    Value: quantity
                },
                {
                    $Type: 'UI.DataField',
                    Value: uom
                }
            ]
        }
    }
);