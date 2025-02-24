sap.ui.define(['sap/fe/test/ObjectPage'], function(ObjectPage) {
    'use strict';

    var CustomPageDefinitions = {
        actions: {},
        assertions: {}
    };

    return new ObjectPage(
        {
            appId: 'de.marianzeis.material',
            componentId: 'MaterialBOMsObjectPage',
            contextPath: '/Material/bomChild'
        },
        CustomPageDefinitions
    );
});