({
  doinit: function (component, event, helper) {
    $A.createComponent(
      "c:PRC_PricingDetails",
      {
        "recordId": component.get('v.recordId')
      },
      function (pricingDetails, status, errorMessage) {
        //Add the new button to the body array
        if (status === "SUCCESS") {
          component.set("v.body", []);
          var body = component.get("v.body");
          body.push(pricingDetails);
          component.set("v.body", body);
          console.log("++++ componente creado");
        }
        else if (status === "INCOMPLETE") {
          console.log("No response from server or client is offline.")
          // Show offline error
        }
        else if (status === "ERROR") {
          console.log("Error: " + errorMessage);
          // Show error message
        }
      }
    );
  }
})