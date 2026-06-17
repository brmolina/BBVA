({
  init: function(component, event, helper) {
    var columns = [{
      type: 'text',
      fieldName: 'description',
      label: $A.get('{!$Label.c.Lc_arce_ratingVariableDescription}'),
      initialWidth: 300
    },
    {
      type: 'number',
      fieldName: 'value',
      label: $A.get('{!$Label.c.Lc_arce_ratingVariableValue}'),
      typeAttributes: { maximumFractionDigits: '2' },
      initialWidth: 175
    },
    {
      type: 'number',
      fieldName: 'score',
      label: $A.get('{!$Label.c.Lc_arce_ratingVariableScore}'),
      typeAttributes: { maximumFractionDigits: '2' },
      initialWidth: 175
    },
    {
      type: 'number',
      fieldName: 'maxScore',
      label: $A.get('{!$Label.c.Lc_arce_ratingVariableMaxScore}'),
      typeAttributes: { maximumFractionDigits: '2' },
      initialWidth: 175
    }
    ];
    var analysisId = component.get('v.recordId');
    component.set('v.gridColumns', columns);
    helper.getData(component, analysisId);
  }
});