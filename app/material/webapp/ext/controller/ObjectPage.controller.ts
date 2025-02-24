import ControllerExtension from 'sap/ui/core/mvc/ControllerExtension';
import ExtensionAPI from 'sap/fe/templates/ObjectPage/ExtensionAPI';
import JSONModel from 'sap/ui/model/json/JSONModel';
import Node from 'sap/suite/ui/commons/networkgraph/Node';
import Context from 'sap/ui/model/odata/v4/Context';
import { ActionButton$PressEvent } from 'sap/suite/ui/commons/networkgraph/ActionButton';

/**
 * @namespace de.marianzeis.material.controller
 * @controller
 */
export default class ObjectPage extends ControllerExtension<ExtensionAPI> {
  static overrides = {
    /**
     * Called when a controller is instantiated and its View controls (if available) are already created.
     * Can be used to modify the View before it is displayed, to bind event handlers and do other one-time initialization.
     * @memberOf de.marianzeis.material.ext.controller.ObjectPage
     */
    onInit(this: ObjectPage) {},

    editFlow: {
      // Called after the save action has been completed.
      // This ensures that, when the user saves changes to a material,
      // the graph is refreshed and any changes to relationships appear in the UI immediately.
      onAfterSave: async function (
        this: ObjectPage,
        mParameters: { context: Context }
      ) {
        await this.loadGraph(mParameters.context);
      },
    },

    routing: {
      // Method to handle the binding context set up after navigation to this view.
      // This typically occurs when a user navigates from the Overview (ListReport) to this ObjectPage or just a reload
      onAfterBinding: async function (
        this: ObjectPage,
        bindingContext: Context
      ) {
        // Once the binding is established, we load the graph for the current material.
        await this.loadGraph(bindingContext);
      },
    },
  };

  /**
   * Event handler for the action button on each node in the graph.
   * This method is triggered when the user clicks "Go to Material" on the node.
   * It uses the node's customData to determine which Material to navigate to.
   */
  onGoToMaterial(this: ObjectPage, event: ActionButton$PressEvent): void {
    // Get the graph instance from the custom section in the Object Page.
    const graph = this.getView().byId(
      'de.marianzeis.material::MaterialObjectPage--fe::CustomSubSection::myCustomSection--graph'
    );
    const nodes = graph.getNodes();
    const buttonNodeId = event.getParameter('id') as String;

    // The node ID typically ends with a number we can match to link the action button to the node.
    const graphNumber = buttonNodeId.split('-').pop();

    // Identify which node was clicked by matching the trailing id part.
    const node = nodes.find((node: Node) =>
      node.getId().endsWith(`-${graphNumber}`)
    );

    if (node) {
      // Retrieve the custom data from the node to get the underlying material ID.
      const customData = node.getCustomData();
      const materialId = customData
        .find((data: any) => data.getKey() === 'materialId')
        .getValue();
      const material_ID = customData
        .find((data: any) => data.getKey() === 'material_ID')
        .getValue();

      // Get the OData V4 model from the extension's base view.
      // We'll create a binding context for the material by ID so that the framework can navigate to it.
      const model = this.base.getView().getModel() as any;
      const bindingPath = `/Material(ID=${material_ID},IsActiveEntity=true)`;
      const context = model.bindContext(bindingPath).getBoundContext();

      // Navigate to the MaterialObjectPage with the context
      this.base.routing.navigate(context, { preserveHistory: true });
    }
  }

  /**
   * Loads the graph data for the current (or newly navigated) Material.
   * This function fetches the GraphNetwork data by calling your CAP service
   * at sPath + '/graph', then sets the data into a JSONModel called 'graphModel'.
   */
  private async loadGraph(this: ObjectPage, context?: Context) {
    const view = this.getView();

    // Initialize the graph settings model if it doesn't exist.
    // This handles busy indicators while the graph is loading.
    if (!view.getModel('graphSettings')) {
      const graphSettings = new JSONModel({
        busy: false,
        busyIndicatorDelay: 0,
      });
      view.setModel(graphSettings, 'graphSettings');
    }

    // Enable busy state while data is loading.
    view.getModel('graphSettings').setProperty('/busy', true);

    // Determine the correct path for the current context.
    // If IsActiveEntity=false is present, switch it to true for reading main data.
    const oMaterialBindingContext = view.getBindingContext();
    let sPath = context ? context.getPath() : oMaterialBindingContext.getPath();
    sPath = sPath.replace(/IsActiveEntity=false/, 'IsActiveEntity=true');

    let data;
    let lines;
    let nodes;
    let groups;

    try {
      // The bound context is used to fetch the 'graph' navigation property from the Material entity.
      // Because of the pseudo-entity in CAP (GraphNetwork), we get back the nodes/lines in JSON form.
      const oModel = view.getModel();
      const oData = await oModel.bindContext(sPath + '/graph');
      await oData.requestObject();

      // Retrieve the raw data from the OData response.
      data = oData.getBoundContext().getObject();

      // Parse JSON strings for nodes, lines, groups. 
      // The code at service.js populates these properties to build the graph.
      if (data.nodes) nodes = JSON.parse(data.nodes);
      if (data.lines) lines = JSON.parse(data.lines);
      if (data.groups) groups = JSON.parse(data.groups);

      // If we successfully got nodes and lines, set them in the 'graphModel', 
      // which in turn is bound to our graph.fragment.xml UI.
      if (data.nodes && data.lines) {
        const oJSONModel = new JSONModel({
          nodes,
          lines,
          groups,
          orientation: 'LeftRight',
        });
        // Increase the size limit if needed to display large amounts of data.
        oJSONModel.setSizeLimit(1000000000);
        view.setModel(oJSONModel, 'graphModel');
      }
    } catch (error) {
      console.error('Error loading graph data:', error);
    } finally {
      // Reset the busy state once data loading is done.
      view.getModel('graphSettings').setProperty('/busy', false);
    }
  }
}
