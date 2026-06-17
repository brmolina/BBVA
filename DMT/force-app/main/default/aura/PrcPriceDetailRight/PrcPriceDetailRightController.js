({
     doInit : function(component, event, helper) {
        var numColumns = component.get('v.matrixColumns');
        switch (numColumns) {
          case 3:
			component.set('v.colSeparator',0);
            break;
          case 4:
            component.set('v.colSeparator',70);
            break;
          case 5:
            component.set('v.colSeparator',150);
            break;
          case 6:
            component.set('v.colSeparator',230);
            break;
          case 7:
            component.set('v.colSeparator',310);
            break;
          default:
            component.set('v.colSeparator',150);
        }
    }

})