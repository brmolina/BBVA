/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/
({//eslint-disable-line
  handleCancel: function(component) {
    // Manual close should exit the parent flow, not just destroy the child form.
    const cmpEvent = component.getEvent('cmpEvent');
    cmpEvent.setParams({
      message: 'Cancel component'
    });
    cmpEvent.fire();
    component.destroy();
  },
  handleClose: function(component) {
    // Map LWC close -> legacy Aura event so parent flow remains unchanged.
    const cmpEvent = component.getEvent('cmpEvent');
    cmpEvent.setParams({
      message: 'Close component'
    });
    cmpEvent.fire();
    component.destroy();
  },
  handleBack: function(component) {
    // Map LWC back -> legacy Aura event to return to duplicate-search screen.
    const cmpEvent = component.getEvent('cmpEvent');
    cmpEvent.setParams({
      message: 'Back component'
    });
    cmpEvent.fire();
    component.destroy();
  }
});
/*CAMBIOS MIGRACIÓN A LWC GLOBAL BANKER*/