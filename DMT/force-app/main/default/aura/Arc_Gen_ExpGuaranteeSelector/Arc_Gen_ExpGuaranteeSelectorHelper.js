({
  arceSelection: function(component, event, helper) {
    let flowSelected = event.target.value;
    switch (flowSelected) {
      case 'IRPFlow':
        component.set('v.processSelected', 'EXPG');
        component.set('v.model', '2021RTC_GEN');
        break;
      case 'DirectCessionFlow':
        component.set('v.processSelected', 'EXPG');
        component.set('v.model', '2021RTC_EXPG');
        break;
    }
  },
});