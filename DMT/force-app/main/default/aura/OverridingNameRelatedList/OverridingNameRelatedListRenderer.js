({
  afterRender: function (component, helper) {
  console.log('Entro en afterRender');
  this.superAfterRender();


      var as = document.getElementsByTagName('th');
      console.log(as.length);
        for(var i=0;i<as.length;i++){

            console.log(as[i]);
          }
    }
})