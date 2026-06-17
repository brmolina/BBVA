({
  doInit: function (cmp, event, helper) {
    var sectionGroupingField = cmp.get("v.sectionGroupingField");
    var columns = [];

    if (sectionGroupingField.includes("solution_category_id__c") === false) {
      columns.push({
        label: "Product",
        fieldName: "productFamily",
        type: "text",
        sortable: true
      });
    }
    if (
      sectionGroupingField.includes("gf_booking_operation_cntry_id__c") ===
      false
    ) {
      columns.push({
        label: "Country",
        fieldName: "country",
        type: "text",
        sortable: true
      });
    }
    columns.push(
      {
        label: "FIRST YEAR ESTIMATED",
        fieldName: "expectedrevenueamount",
        type: "currency",
        sortable: true
      },
      {
        label: "WALLET SIZE",
        fieldName: "gfestginclclproductamount",
        type: "currency",
        sortable: true
      },
      {
        label: "WALLET SHARE",
        fieldName: "bbvashareofwalletper",
        type: "percent",
        sortable: true
      },
      {
        label: "OPP LEVEL",
        fieldName: "gfpotencialleveloppytype",
        type: "text",
        sortable: true
      },
      {
        label: "SUSTAINABILITY",
        fieldName: "gflclprdtsustnbloppyname",
        type: "text",
        sortable: true
      },
      {
        label: "COMMENTS",
        fieldName: "otherinformationdesc",
        type: "text",
        sortable: true
      }
    );
    cmp.set("v.gridColumns", columns);
    var gridGroupingField = cmp.get("v.gridGroupingField");
    console.log("SORT FIELD VALUE : " + gridGroupingField);
    var sortField = gridGroupingField.substring(
      0,
      gridGroupingField.length - 3
    );
    console.log("SORT FIELD VALUE : " + sortField);
    cmp.set("v.sortField", sortField);
    helper.onInit(cmp, event, helper);
  },

  onInit: function (cmp, event, helper) {
    var retrieve = helper.retrieveData(cmp, event, helper);
  },
  retrieveData: function (cmp, event, helper) {
    return new Promise(function (resolve, reject) {
      var action = cmp.get("c.getGridData");
      var parentquery = cmp.get("v.parentId");
      var sectionquery = cmp.get("v.sectionGroupingFieldValue");
      action.setParams({
        parentquery: parentquery,
        sectionquery: sectionquery,
        gridGroupingField: cmp.get("v.gridGroupingField"),
        bpVersionId: cmp.get("v.bpVersionId"),
        lastValidatedV: cmp.get("v.lastValidatedVersion")
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          cmp.set("v.gridData", JSON.parse(response.getReturnValue()));
          resolve(console.log("getgriddata result : " + cmp.get("v.gridData")));
        } else {
          reject(console.log("Ha fallado la llamada al getGridData"));
          console.log(
            "El body de la response es : " + response.getReturnValue()
          );
        }
      });
      $A.enqueueAction(action);
    });
  },
  getTableData: function (cmp, event, helper) {
    var action = cmp.get("c.getTableData");
    var parentquery = cmp.get("v.parentId");
    var sectionquery = cmp.get("v.sectionGroupingFieldValue");
    action.setParams({
      parentquery: parentquery,
      sectionquery: sectionquery,
      gridGroupingField: cmp.get("v.gridGroupingField"),
      bpVersionId: cmp.get("v.bpVersionId"),
      lastValidatedV: cmp.get("v.lastValidatedVersion")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        cmp.set("v.spinnerGrid", false);
        cmp.set("v.data", JSON.parse(response.getReturnValue()));
      } else {
        console.log("Ha fallado la llamada al getTableData");
      }
    });
    $A.enqueueAction(action);
  },
  initializeDataTable: function (cmp, event, helper) {
    var columns = [];
    var sectionGroupingField = cmp.get("v.sectionGroupingField");
    console.log("table section grouping field : " + sectionGroupingField);

    if (sectionGroupingField.includes("solution_category_type__c") === false) {
      columns.push({
        label: "Product",
        fieldName: "productName",
        type: "text"
      });
    }
    if (
      sectionGroupingField.includes("gf_booking_operation_cntry_id__c") ===
      false
    ) {
      columns.push({ label: "Country", fieldName: "country", type: "text" });
    }
    columns.push(
      {
        label: "FIRST YEAR ESTIMATED",
        fieldName: "expectedrevenueamount",
        type: "currency"
      },
      {
        label: "WALLET SIZE",
        fieldName: "gfestginclclproductamount",
        type: "currency",
        editable: true
      },
      {
        label: "WALLET SHARE",
        fieldName: "bbvashareofwalletper",
        type: "text",
        editable: true
      },
      {
        label: "OPP LEVEL (High/Medium/Low)",
        fieldName: "gfpotencialleveloppytype",
        type: "text",
        editable: true
      },
      {
        label: "SUSTAINABILITY (Yes/No)",
        fieldName: "gflclprdtsustnbloppyname",
        type: "text",
        editable: true
      },
      {
        label: "COMMENTS",
        fieldName: "otherinformationdesc",
        type: "text",
        editable: true
      }
    );
    if (sectionGroupingField.includes("solution_category_id__c") === false) {
      columns.push({
        label: "Family",
        fieldName: "productFamily",
        type: "text",
        sortable: true
      });
    }
    cmp.set("v.columns", columns);
  },
  handleSaveData: function (cmp, event, helper) {
    var save = cmp.get("c.saveData");
    var draftValues = event.getParam("draftValues");
    console.log("TROWS" + draftValues);
    console.log(draftValues);
    save.setParams({
      tablerows: JSON.stringify(event.getParam("draftValues"))
    });
    save.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        cmp.set("v.spinnerGrid", true);
        cmp.set("v.draftValues", []);
        helper.getTableData(cmp, event, helper);
        helper.retrieveData(cmp, event, helper);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message:
            "Business Plan " +
            cmp.get("v.sectionGroupingFieldValue") +
            " was successfully updated",
          key: "info_alt",
          type: "success"
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(save);
  },
  sortData: function (component, fieldName, sortDirection) {
    var data = component.get("v.data");
    var key = function (x) {
      return x[fieldName];
    };
    var reverse = sortDirection === "asc" ? 1 : -1;
    var isnumeric = function (value) {
      return typeof value === "number";
    };
    var isnumericresult = isnumeric(data[0][fieldName]);
    console.log("isnumeric " + isnumericresult);
    if (isnumericresult) {
      data.sort(function (a, b) {
        var first = key(a) ? key(a) : "";
        var second = key(b) ? key(b) : "";
        return reverse * ((first > second) - (second > first));
      });
    } else {
      data.sort(function (c, d) {
        var first = key(c) ? key(c).toLowerCase() : "";
        var second = key(d) ? key(d).toLowerCase() : "";
        return reverse * ((first > second) - (second > first));
      });
    }
    component.set("v.data", data);
  }
});