({
    doInit : function(cmp) {
        if(cmp.get('v.isPreview')){

            var masterDataTable = cmp.get('v.masterData');
            var cifsOrigin = [];
            for(var ind = 0; ind<masterDataTable.length ; ind ++){
               if(masterDataTable[ind].bundleAddedNumber>0){
                cifsOrigin.push('Bundle ' + masterDataTable[ind].bundleOrigin + ' -> ' + masterDataTable[ind].bundleAddedNumber + ' CIF');
               } 
            }
            cmp.set('v.commentTittle' , 'Preview final configured Bundle');
            cmp.set('v.cifsOrigin' , cifsOrigin);
        }else{
            cmp.set('v.commentTittle' , cmp.get('v.bundle.description'));
        }
    }
})