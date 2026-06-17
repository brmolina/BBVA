({
  putZero: function(fields) {
    var fieldExp = ['arce__banrel_current_limit_name__c', 'arce__banrel_commitment_name__c',
      'arce__banrel_uncommitment_name__c', 'arce__banrel_outstanding_name__c'];
    for (var i = 0; i < fieldExp.length; i++) {
      for (var fiel in fields) {
        if (fiel === fieldExp[i] && (fields[fiel] < 0 || !fields[fiel])) {
          fields[fiel] = 0;
        }
      }
    }
  }
});