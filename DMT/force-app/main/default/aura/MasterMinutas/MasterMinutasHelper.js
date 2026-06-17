({
	getTableData : function(cmp) {
        var actionDo = cmp.get('c.createMinuteTable');
            actionDo.setParams({
            "year": cmp.get("v.year")
                });
		actionDo.setCallback(this, $A.getCallback(function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                if(response.getReturnValue() ==="") {
                    var toast = $A.get('e.force:showToast');
                    toast.setParams({
                        "title": "Error!",
                        "message": "The year has not record."
                    });
                    toast.fire();
                } else {
                var resultData = JSON.parse(response.getReturnValue());
                cmp.set('v.myData', resultData);
                  }
			} else if (state === "ERROR") {
				var errores = response.getError();
				console.log(JSON.stringify(errores));
			}
		}));
		$A.enqueueAction(actionDo);
    },

    sortData: function (cmp, fieldNam, sortDir) {
        var data = cmp.get("v.myData");
        var rever = sortDir !== 'asc';
        data.sort(this.sortBy(fieldNam, rever))
        cmp.set("v.myData", data);
    },
    sortBy: function (field, rever, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        rever = !rever ? 1 : -1;
        return function (a, b) {
            a = key(a);
            b = key(b);
            return rever * ((a > b) - (b > a));
        }
    },

    convertArrayOfObjectsToCSV : function(component,objectRecords){
        // declare variables
        var csvStringResult, counter, keys, headers, columnDivider, lineDivider;

        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
         }
        // store ,[comma] in columnDivider variabel for sparate CSV values and
        // for start next line use '\n' [new line] in lineDivider varaible
        columnDivider = ',';
        lineDivider =  '\n';

        // in the keys valirable store fields API Names as a key
        // this labels use in CSV file header
        keys = ['nbcDate','nbcRegion',/*'nbcUrl',*/'bookOff','industry','banker','borrower','nOperation','guarantor','groupClient'/*,'groupCliURL'*/,
        'intRating','dealType','bilateral','productArea','product','currencyTranch','underwritting','finalTake','finalTakeEUR','EADs','newMoneyEUR',
        'rar','rorc','expectedRar','cibDeskPast','cibDeskNow','rorcCIBSell','rorcCIB','clientRorc','allInDrawn','allInUnDrawn','tenor','avgLife',
        'floorClause','syndicationOp','sustainableDeal','xSell','sppiTest','sectorialNorm','comments','decision','gcParticipant','gtbParticipant',
        'gfParticipant','riskParticipant','cibParticipant'];

        headers = ['Fecha','NBC',/*'nbcUrl',*/'Booking Office','Industry','Banker','Borrower','N Operacion','Guarantor',
        'Grupo'/*,'groupCliURL'*/,'Internal Rating','Deal Type','Bilateral/Syndicated',
        'Product Area','Product','Currency','Underwritting',
        'Final Take(Mn)','Final Take (EUR Mn)','EAD','New Money EUR','RAROEC','RORC','Expected Global RaR',
        'CIB Desktop Past','CIB Desktop Now','Expected Global RORC CIB w/o X-sell','Expected Global RORC CIB','Client\'s Global RORC CIB',
        'All-in (drawn)','All-in (undrawn)','Tenor','Vida Media',
        'Clausula Suelo','Syndication opinion','Sustainable Deal','X-Sell Committee Monitoring','SPPI Test',
        'Sectorial norm','Comments','Decision','GC Participant','GTB Participant',
        'IBF Participant','Risk Participant','CIB geography'];

        csvStringResult = '';
        csvStringResult += headers.join(columnDivider);
        csvStringResult += lineDivider;

        for(var i=0; i < objectRecords.length; i++){
            counter = 0;

             for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;

              // add , [comma] after every String value,. [except first]
                  if(counter > 0){
                      csvStringResult += columnDivider;
                   }

               csvStringResult += '"'+ objectRecords[i][skey]+'"';

               counter++;

            } // inner for loop close
             csvStringResult += lineDivider;
        }// outer main for loop close

        // return the CSV formate String
        return csvStringResult;
    }
})