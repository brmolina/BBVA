({ // eslint-disable-line
  doInit: function(cmp, event, helper) {
  },

  updateOptions: function(cmp, event, helper) {
    var options = event.getParam('arguments');
    cmp.set('v.options_', options.newOptions);

    helper.setOptions(cmp, event);
  },

  handleClick: function(cmp, event, helper) {
    var mainDiv = cmp.find('main-div');
    $A.util.addClass(mainDiv, 'slds-is-open');
  },

  handleSelection: function(cmp, event, helper) {
    var item = event.currentTarget;
    if (item && item.dataset) {
        var value = item.dataset.value;
        var options = cmp.get('v.options_');

        // 🔁 Alternar selección sin necesidad de SHIFT
        options.forEach(function(element) {
            if (element.value === value) {
                element.selected = !element.selected;
            }
        });

        cmp.set('v.options_', options);

        var values = helper.getSelectedValues(cmp);
        var labels = helper.getSelectedLabels(cmp);

        helper.setInfoText(cmp, labels);
        helper.dispatchSelectChangeEvent(cmp, values);
      }
  },

  handleMouseLeave: function(cmp, event, helper) {
    cmp.set('v.dropdownOver', false);
    var mainDiv = cmp.find('main-div');
    $A.util.removeClass(mainDiv, 'slds-is-open');
  },

  handleMouseEnter: function(cmp, event, helper) {
    cmp.set('v.dropdownOver', true);
  },

  handleMouseOutButton: function(cmp, event, helper) {
    window.setTimeout(
      $A.getCallback(function() {
        if (cmp.isValid()) {
          //if dropdown over, user has hovered over the dropdown, so don't close.
          if (cmp.get('v.dropdownOver')) {
            return;
          }
          var mainDiv = cmp.find('main-div');
          $A.util.removeClass(mainDiv, 'slds-is-open');
        }
      }), 200
    );
  }
});