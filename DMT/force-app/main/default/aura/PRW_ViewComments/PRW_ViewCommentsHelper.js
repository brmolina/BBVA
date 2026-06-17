({
  doInit : function(cmp, event, helper) {
    let products = cmp.get('v.products');
    cmp.set('v.optimalP', Intl.NumberFormat('cat-ES' , {minimumFractionDigits: 4}).format(parseFloat(products.simulatedP).toFixed(4)));
    cmp.set('v.optimalQ', Intl.NumberFormat('cat-ES' ).format(products.simulatedQ));
    if(products.displayIconName === 'utility:warning'){
      cmp.set('v.observations', products.notificationDescription);
    }else{
      cmp.set('v.observations', products.description);
    }
      
    for(var ind3 = 0; ind3 < products.indicators.length; ind3++) {
      if(products.indicators[ind3].details.indicatorType === 'STRATEGY') {
        cmp.set('v.strategy', products.indicators[ind3].details.strategy);
      } else if(products.indicators[ind3].details.indicatorType === 'ELASTICITY') {
        let concat = products.indicators[ind3].details.elasticity.id_y.replaceAll('_',' ') + '. ' + products.indicators[ind3].details.elasticity.description;
        cmp.set('v.elasticity', concat);
      }
    }
  }
})