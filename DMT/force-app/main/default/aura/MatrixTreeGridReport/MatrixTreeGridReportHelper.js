({
    onInit: function (cmp, event, helper) {
        helper.retrieveData(cmp, event, helper);

    },
    retrieveData: function (cmp, event, helper) {
        let nestedData = cmp.get("c.getInfo");
        let parametros = helper.prepareParams(cmp, event, helper);
        console.log('::::::::parametros:' + parametros);

        nestedData.setParams({
            "attributes": parametros
        });

        nestedData.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let resultData = JSON.parse(response.getReturnValue());
                if (resultData != null) {
                    let columnas = resultData.wrColumns;
                    let datos = resultData.wrData;
                    let localCur = resultData.localeCurrency;
                    //inseta las columnas
                    datos=helper.insertColumns(datos,columnas);
                    columnas=JSON.parse(JSON.stringify(columnas).replace(/typeReplaceMe/g,"type"));
                    cmp.set('v.gridColumns', columnas);
                    cmp.set("v.gridData", datos);
                    cmp.set("v.localCurrency", localCur);
                    helper.expandAllRows(cmp, event);
                }
            }
        });
        $A.enqueueAction(nestedData);
    },
    insertColumns : function(datos,columnas)
    {
        datos=JSON.parse(JSON.stringify(datos).replace(/_children/g,"children"));
        for(var i=0;i<datos.length;i++) {
            for(var jk=0;jk<datos[i].lstRevenuesByProduct.length;jk++) {
                if(columnas[jk].fieldName.indexOf("name")===-1) {
                    datos[i][""+columnas[jk].fieldName+""] =""+ datos[i].lstRevenuesByProduct[jk]+"";
                }
            }
            //carga las columnas de los productos
            for(var k=0;k<datos[i].children.length;k++) {
                for(var j=0;j<datos[i].children[k].lstRevenuesByProduct.length;j++) {
                    if(columnas[j].fieldName.indexOf("name")===-1) {
                        datos[i].children[k][""+columnas[j].fieldName+""] = ""+datos[i].children[k].lstRevenuesByProduct[j]+"";
                    }
                }
            }
        }
        datos=JSON.parse(JSON.stringify(datos).replace(/children/g,"_children"));
        return datos;
    },
    prepareParams: function (cmp, event, helper) {
        let recordId = cmp.get("v.recordId");
        let labelFirstGr = cmp.get("v.groupByLabelPrimary");
        let labelSecondGr = cmp.get("v.groupByLabelSecondary");
        let fieldFirstGr = cmp.get("v.groupByFieldPrimary");
        let fieldSecondGr = cmp.get("v.groupByFieldSecondary");
        let modoAgrupacion = (cmp.get("v.mode") === "") ? labelFirstGr.toUpperCase() : cmp.get("v.mode");
        let queryInput = cmp.get("v.queryInput");
        let labelTotalColumn = cmp.get("v.labelTotalColumn"); //lo controlo en serverside mejor, valor por defecto global
        let fieldRowPrimary = cmp.get("v.fieldRowPrimary");
        let fieldRowChild = cmp.get("v.fieldRowChild");
        let fieldDecimalValues = cmp.get("v.fieldDecimalValues");
        console.log('label total column? : ' + labelTotalColumn);

        console.log(':::modoAgrupacion : ' + modoAgrupacion);


        let paramsJSON = cmp.get("v.mapAtrributes");
        paramsJSON["recordId"] = recordId;
        paramsJSON["columnsGroupBy"] = modoAgrupacion;
        paramsJSON["queryInput"] = queryInput;
        paramsJSON["labels"] = {
            labelFirstGr: labelFirstGr,
            labelSecondGr: labelSecondGr,
            fieldFirstGr: fieldFirstGr,
            fieldSecondGr: fieldSecondGr,
            labelTotalColumn: labelTotalColumn,
            fieldRowPrimary: fieldRowPrimary,
            fieldRowChild: fieldRowChild,
            fieldDecimalVal: fieldDecimalValues
        };
        return JSON.stringify(paramsJSON);
    },
    expandAllRows: function (cmp, event) {
        let tree = cmp.find('matrixTreeGridReport');
        tree.expandAll();
    },
    createButton: function (cmp, event, helper) {
        console.log("::::::::createButton::");
        let labelFirstGr = cmp.get("v.groupByLabelPrimary");
        let labelSecondGr = cmp.get("v.groupByLabelSecondary");
        let fieldSecondGr = cmp.get("v.groupByFieldSecondary");
        let modoAgrupacion = (cmp.get("v.mode") === "") ? labelFirstGr.toUpperCase() : cmp.get("v.mode");
        let nextButtonLabel = (modoAgrupacion === labelFirstGr.toUpperCase()) ? 'Switch Group by ' + labelSecondGr : 'Switch Group by ' + labelFirstGr;

        console.log("::::::::modoAgrupacion::" + modoAgrupacion);
        console.log("::::::::labelFirstGr::" + labelFirstGr);
        console.log("::::2::::labelSecondGr::" + labelSecondGr);
        console.log("::::2::::fieldSecondGr::" + fieldSecondGr);
        console.log("::::::::nextButtonLabel::" + nextButtonLabel);

        var butCmp = cmp.find("buttomSwitchMode");
        if (butCmp) {
            butCmp.destroy();
        }
        if (labelSecondGr !== undefined && fieldSecondGr !== undefined) {
            console.log("::::::::createComponent button::");
            $A.createComponent(
                "lightning:button",
                {
                    "aura:id": "buttomSwitchMode",
                    "label": nextButtonLabel,
                    "onclick": cmp.getReference("c.handlePress"),
                    "class": "buttonSwitch"
                },
                function (newButton, status, errorMessage) {
                    if (status === "SUCCESS") {
                        var body = cmp.get("v.body");
                        body.push(newButton);
                        cmp.set("v.body", body);
                    }
                    else if (status === "INCOMPLETE") {
                        console.log("No response from server or client is offline.")
                    }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                    }
                }
            );
        }
    },

    onHandlePress: function (cmp, event, helper) {
        var labelFirstGr = cmp.get("v.groupByLabelPrimary");
        var labelSecondGr = cmp.get("v.groupByLabelSecondary");
        console.log("button: " + cmp.find("buttomSwitchMode"));
        console.log("button pressed");
        var modoAgrupacion = cmp.get("v.mode").toUpperCase();
        console.log(':::pre: ' + modoAgrupacion);
        if (modoAgrupacion === labelSecondGr.toUpperCase()) {
            modoAgrupacion = labelFirstGr.toUpperCase();
        } else {
            modoAgrupacion = labelSecondGr.toUpperCase();
        }
        cmp.set("v.mode", modoAgrupacion);
        console.log(':::post: ' + modoAgrupacion);
        helper.retrieveData(cmp, event, helper);

        helper.createButton(cmp, event, helper);
    }
})