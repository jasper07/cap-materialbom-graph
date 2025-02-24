sap.ui.require(
    [
        'sap/fe/test/JourneyRunner',
        'de/marianzeis/material/test/integration/FirstJourney',
		'de/marianzeis/material/test/integration/pages/MaterialList',
		'de/marianzeis/material/test/integration/pages/MaterialObjectPage',
		'de/marianzeis/material/test/integration/pages/MaterialBOMsObjectPage'
    ],
    function(JourneyRunner, opaJourney, MaterialList, MaterialObjectPage, MaterialBOMsObjectPage) {
        'use strict';
        var JourneyRunner = new JourneyRunner({
            // start index.html in web folder
            launchUrl: sap.ui.require.toUrl('de/marianzeis/material') + '/index.html'
        });

       
        JourneyRunner.run(
            {
                pages: { 
					onTheMaterialList: MaterialList,
					onTheMaterialObjectPage: MaterialObjectPage,
					onTheMaterialBOMsObjectPage: MaterialBOMsObjectPage
                }
            },
            opaJourney.run
        );
    }
);