import ControllerExtension from 'sap/ui/core/mvc/ControllerExtension';
import ExtensionAPI from 'sap/fe/templates/ObjectPage/ExtensionAPI';
import { ActionButton$PressEvent } from 'sap/suite/ui/commons/networkgraph/ActionButton';

/**
 * @namespace de.marianzeis.material.controller
 * @controller
 */
export default class ObjectPage extends ControllerExtension<ExtensionAPI> {
  /**
   * Event handler for the action button on each node in the graph.
   * This method is triggered when the user clicks "Go to Material" on the node.
   * It uses the node's customData to determine which Material to navigate to.
   */
  onGoToMaterial(this: ObjectPage, event: ActionButton$PressEvent): void {
    // Define a type for the object
    type MaterialObject = {
      ID: string;
    };

    // Get the binding context object
    const bindingContext = event.getSource()?.getBindingContext();
    const object = bindingContext?.getObject() as MaterialObject | null;
    if (object && object.ID) {
      // Type guard to ensure object is not null or undefined
      this.base.getExtensionAPI().getRouting().navigateToRoute('MaterialObjectPage', {
        key: `ID=${object.ID},IsActiveEntity=true`,
      });
    }
  }
}
