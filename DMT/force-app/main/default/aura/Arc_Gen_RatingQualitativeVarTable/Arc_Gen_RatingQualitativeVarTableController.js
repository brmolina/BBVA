({
  init: function(component, event, helper) {
    var columns = [{
      type: 'text',
      fieldName: 'description',
      label: $A.get('{!$Label.c.Lc_arce_ratingQualitativeBlock}'),
      initialWidth: 300
    },
    {
      type: 'text',
      fieldName: 'answer',
      label: $A.get('{!$Label.c.Lc_arce_ratingVariableAnswer}')
    }
    ];
    var analysisId = component.get('v.recordId');
    component.set('v.columns', columns);
    helper.getData(component, analysisId);
  }
});