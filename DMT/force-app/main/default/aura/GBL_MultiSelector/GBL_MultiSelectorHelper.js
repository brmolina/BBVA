({ // eslint-disable-line
  setInfoText: function(cmp, labels) {
    if (labels !== null) {
      if (labels.length === 0) {
        cmp.set('v.infoText', 'Selector de Relaciones');
      } else if (labels.length === 1) {
        cmp.set('v.infoText', labels[0]);
      } else if (labels.length > 1) {
        cmp.set('v.infoText', labels.length + ' Selected');
      }
    }
  },

  getSelectedValues: function(cmp) {
    var options = cmp.get('v.options_');
    var values = [];
    options.forEach(function(element) {
      if (element.selected) {
        values.push(element.value);
      }
    });
    return values;
  },

  getSelectedLabels: function(cmp) {
    var options = cmp.get('v.options_');
    var labels = [];
    options.forEach(function(element) {
      if (element.selected) {
        labels.push(element.label);
      }
    });
    return labels;
  },

  setOptions: function(cmp, event) {
    var selLabels = this.getSelectedLabels(cmp);
    var selValues = this.getSelectedValues(cmp);
    this.setInfoText(cmp, selLabels);
    this.dispatchOptionsLoadedEvent(cmp, selValues, true);
  },


  dispatchSelectChangeEvent: function(cmp, values) {
    var compEvent = cmp.getEvent('selectChange');
    compEvent.setParams({ 'values': values });

    compEvent.fire();
  },

  dispatchOptionsLoadedEvent: function(cmp, values, result) {
    var compEvent = cmp.getEvent('optionsLoaded');
    compEvent.setParams({ 'result': result });
    compEvent.setParams({ 'values': values });

    compEvent.fire();
  }
});