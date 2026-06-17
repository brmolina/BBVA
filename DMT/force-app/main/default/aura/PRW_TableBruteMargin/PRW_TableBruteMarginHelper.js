({
  DATA: [
  ],
  setColumns: function(cmp) {
      let columnsArray = $A.get('$Label.c.PRW_ColumnsTableMargin');
      let columnsList = columnsArray.split('||');
      let numColumns = columnsList.length;

      var columns = [];
      columns = [
        {label: columnsList[0], fieldName: 'product', type: 'text', wrapText: true},
        {label: columnsList[numColumns - (numColumns - 1)], fieldName: 'revenues', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 2)], fieldName: 'revenuesYTD', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 3)], fieldName: 'percentYoY_YTD', type: 'text',  cellAttributes: {alignment: 'right'},typeAttributes:{step: '0.1',maximumFractionDigits:'1',minimumFractionDigits: '1'}},
        {label: columnsList[numColumns - (numColumns - 4)], fieldName: 'revenuesL12M', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 5)], fieldName: 'percentYoYL12M', type: 'text',  cellAttributes: {alignment: 'right'} ,typeAttributes:{step: '0.1',maximumFractionDigits:'1',minimumFractionDigits: '1'}}
      ]
      cmp.set('v.columns', columns);
    },
    getParticipants: function(cmp, helper) {
      var actionPart = cmp.get('c.gtParticipants');
      actionPart.setParams({
        idCuaderno: cmp.get('v.profSheetId')
      });
      var promise = this.promisifyMargin(actionPart);
      return promise.then(
        $A.getCallback(function(result) {
          let idsAux = [];
          for (let ind = 0; ind < result.length; ind++) {
            var customerID = result[ind].cuco__participant_id__r.g_customer_id__c;
            customerID= customerID.substring(customerID.length - 9);
            idsAux.push(customerID);
          }
          let ids = idsAux.join('-');
          cmp.set('v.lAccountId', ids);
          helper.setData(cmp, helper);
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionPart + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
    },
    setData: function(cmp, helper) {
      var actionMargin = cmp.get('c.gtDataMargin');

      actionMargin.setParams({
        laccountsId: cmp.get('v.lAccountId'),
        profSheetStart: cmp.get('v.profSheetStart'),
        profSheetEnd: cmp.get('v.profSheetEnd')
      });
      var promise = this.promisifyMargin(actionMargin);
      return promise.then(
        $A.getCallback(function(result) {
          if(result.success === true) {
            let dataTF = [];
            let dataWC = [];
            let dataCM = [];
            let totalCM = 0;
            let totalWC = 0;
            let totalTF = 0;
            let totalpastYearTF = 0;
            let totalpastYearWC = 0;
            let totalpastYearCM = 0;
            let totalPerYoYCM = 0;
            let totalPerYoYWC = 0;
            let totalPerYoYTF = 0;
            let maximumDate = result.maximumDate;
            let tableData = JSON.parse(result.tableData);
            let formatDate = new Date(maximumDate);
            const month = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio","Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
            const finalDate = month[formatDate.getMonth()] + ' ' + formatDate.getFullYear();

            for(var ind = 0; ind < tableData.length; ind++) {
              if(tableData[ind].subFamily == 'WC'){
                dataWC.push(
                  {
                    channel : tableData[ind].channel,
                    revenues : helper.formatCurrency(tableData[ind].revenues),
                    revenuesYTD : helper.formatCurrency(tableData[ind].revenuesYTD),
                    percentYoY_YTD : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoY_YTD))+ ' %',
                    revenuesL12M : helper.formatCurrency(tableData[ind].revenuesL12M),
                    product : tableData[ind].product,
                    percentYoYL12M : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoYL12M))+ ' %'
                  }
                );
                totalWC = totalWC + parseFloat(tableData[ind].revenuesYTD);
                //totalpastYearWC = totalpastYearWC + (parseFloat(tableData[ind].revenues) * ((100 - parseFloat(tableData[ind].percentYoY_YTD))/100));
                totalpastYearWC = totalpastYearWC + parseFloat(tableData[ind].valueLastPeriod);
              }else if(tableData[ind].subFamily == 'GTF'){
                dataTF.push(
                  {
                    channel : tableData[ind].channel,
                    revenues : helper.formatCurrency(tableData[ind].revenues),
                    revenuesYTD : helper.formatCurrency(tableData[ind].revenuesYTD),
                    percentYoY_YTD : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoY_YTD))+ ' %',
                    revenuesL12M : helper.formatCurrency(tableData[ind].revenuesL12M),
                    product : tableData[ind].product,
                    percentYoYL12M : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoYL12M))+ ' %'
                  }
                );
                totalTF = totalTF + parseFloat(tableData[ind].revenuesYTD);
                //totalpastYearTF = totalpastYearTF + (parseFloat(tableData[ind].revenues) * ((100 - parseFloat(tableData[ind].percentYoY_YTD))/100));
                totalpastYearTF = totalpastYearTF + parseFloat(tableData[ind].valueLastPeriod);
              }else if(tableData[ind].subFamily == 'CM'){
                dataCM.push(
                  {
                    channel : tableData[ind].channel,
                    revenues :helper.formatCurrency(tableData[ind].revenues),
                    revenuesYTD : helper.formatCurrency(tableData[ind].revenuesYTD),
                    percentYoY_YTD : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoY_YTD))+ ' %',
                    revenuesL12M : helper.formatCurrency(tableData[ind].revenuesL12M),
                    product : tableData[ind].product,
                    percentYoYL12M : Intl.NumberFormat('cat-ES',{minimumFractionDigits:'2', maximumFractionDigits:'2' }).format(parseFloat(tableData[ind].percentYoYL12M))+ ' %'
                  }
                );
                totalCM = totalCM + parseFloat(tableData[ind].revenuesYTD);
                //totalpastYearCM = totalpastYearCM + (parseFloat(tableData[ind].revenues) * ((100 - parseFloat(tableData[ind].percentYoY_YTD))/100));
                totalpastYearCM = totalpastYearCM + parseFloat(tableData[ind].valueLastPeriod);
              }

            }
            if(totalpastYearWC != 0){
              totalPerYoYWC = ((totalWC - totalpastYearWC)/totalpastYearWC ) * 100;
              totalPerYoYWC = Math.floor(totalPerYoYWC * 100) / 100;
            }else{
              totalPerYoYWC = 0;
            }
            if(totalpastYearCM != 0){
              totalPerYoYCM = ((totalCM - totalpastYearCM)/totalpastYearCM ) * 100;
              totalPerYoYCM = Math.floor(totalPerYoYCM * 100) / 100;
            }else{
              totalPerYoYCM = 0;
            }
            if(totalpastYearTF != 0){
              totalPerYoYTF = ((totalTF - totalpastYearTF)/totalpastYearTF ) * 100;
              totalPerYoYTF = Math.floor(totalPerYoYTF * 100) / 100;
            }else{
              totalPerYoYTF = 0;
            }
            cmp.set('v.loaded', true);
            cmp.set('v.dataWC', dataWC);
            cmp.set('v.dataTF', dataTF);
            cmp.set('v.dataCM', dataCM);
            cmp.set('v.totalTF',helper.formatCurrency(totalTF));
            cmp.set('v.totalCM',helper.formatCurrency(totalCM));
            cmp.set('v.totalWC',helper.formatCurrency(totalWC));
            cmp.set('v.totalCMYoY',totalPerYoYCM);
            cmp.set('v.totalWCYoY',totalPerYoYWC);
            cmp.set('v.totalTFYoY',totalPerYoYTF);
            cmp.set('v.maximumDate',finalDate);
          }
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionMargin + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
    },
    promisifyMargin: function(actionMargin) {
      return new Promise((resolve, reject) => {
        actionMargin.setCallback(this, function(response) {
          const statusVolume = response.getState();
          if (statusVolume === 'SUCCESS') {
            const returnValue = response.getReturnValue();
            resolve(returnValue);
          } else if (statusVolume === 'ERROR') {
            var errorsVolume = response.getError();
            if (errorsVolume) {
              if (errorsVolume[0] && errorsVolume[0].message) {
                reject(Error('Error message: ' + errorsVolume[0].message));
              }
            } else {
              reject(Error('Unknown error'));
            }
          }
        });
        $A.enqueueAction(actionMargin);
      });
    },

    formatCurrency: function(number){
      return Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(number);
    }
})