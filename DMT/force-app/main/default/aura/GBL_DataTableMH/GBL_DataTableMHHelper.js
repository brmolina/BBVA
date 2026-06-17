({
  //eslint-disable-line no-unused-expressions
  executeAction: function (cmp, action, callback) {
    //Promise Execute action against the server
    return new Promise(function (resolve, reject) {
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve(response.getReturnValue());
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(Error("Error message: " + errors[0].message));
            }
          } else {
            reject(Error("Unknown error"));
          }
        }
      });
      $A.enqueueAction(action);
    });
  },

  //orchestrate query to the server
  fetchData: function (cmp, event, helper) {
    const recordId = cmp.get("v.accountId");
    const vision = cmp.get("v.selectedVision");
    const types = cmp.get("v.selectedHTypes");

    // ⛔ No continuar si no hay datos básicos
    if (!recordId || !vision || !types || types.length === 0) {
      console.warn("⛔ fetchData detenido: faltan parámetros");
      return;
    }

    // Si todo va bien, continúa con fetchTotalRows + getData
    helper.fetchTotalRows(cmp, event).then(
      $A.getCallback(function () {
        helper.getData(cmp, event);
      })
    );
  },
  //retrieve records
  fetchTotalRows: function (cmp, event) {
    var action = cmp.get("c.fetchData");
    var recordId = cmp.get("v.accountId");
    var vision = cmp.get("v.selectedVision");
    var types = cmp.get("v.selectedHTypes");
    var searchKey = cmp.get("v.searchKey");
    var acmhAvailable = cmp.get("v.ACMHAvailable");
    var useStandard = cmp.get("v.useStandard");
    var accountTypeField = cmp.get("v.accountTypeField");
    var startFromRow = cmp.get("v.startFromRow");

    action.setParams({
      useStandard: useStandard,
      recordId: recordId,
      vision: vision,
      types: types,
      searchKey: searchKey,
      accountTypeField: accountTypeField,
      returnTotal: true,
      startFromRow: startFromRow
    });

    var dataPromise = this.executeAction(cmp, action);

    return dataPromise.then(
      $A.getCallback(function (result) {
        var parsedResult = JSON.parse(result);
        cmp.set("v.totalRows", parsedResult);
      }),
      $A.getCallback(function (error) {
        console.log(
          "fetchTotalRows promise finished with errors: " + error.message
        );
      })
    );
  },

  //retrieve records
  getData: function (cmp, event, helper) {
    var action = cmp.get("c.fetchData");
    var recordId = cmp.get("v.accountId");
    var vision = cmp.get("v.selectedVision");
    var types = cmp.get("v.selectedHTypes");
    var searchKey = cmp.get("v.searchKey");
    var useStandard = cmp.get("v.useStandard");
    var accountTypeField = cmp.get("v.accountTypeField");
    var startFromRow = cmp.get("v.startFromRow");

    action.setParams({
      useStandard: useStandard,
      recordId: recordId,
      vision: vision,
      types: types,
      searchKey: searchKey,
      accountTypeField: accountTypeField,
      returnTotal: false,
      startFromRow: startFromRow
    });

    if (cmp.get("v.startFromRow") === "START") {
      cmp.set("v.objData", []);
    }

    var dataPromise = this.executeAction(cmp, action);
    return dataPromise.then(
      $A.getCallback(function (result) {
        var parsedResult = JSON.parse(result);
        var visibleNodeIds = cmp.get("v.visibleNodeIds");
        if (visibleNodeIds && visibleNodeIds.length > 0) {
          parsedResult = parsedResult.filter((rec) =>
            visibleNodeIds.includes(rec.Child_Account__c)
          );
        }

        var searchKey = cmp.get("v.searchKey");
        if (searchKey && searchKey.trim() !== "") {
          const lowerKey = searchKey.toLowerCase();
          parsedResult = parsedResult.filter(
            (record) =>
              record.recordName &&
              record.recordName.toLowerCase().includes(lowerKey)
          );
        }

        var currentData = cmp.get("v.objData");
        var newData;

        if (cmp.get("v.startFromRow") === "START") {
          newData = parsedResult;
        } else {
          newData = currentData.concat(parsedResult);
        }

        cmp.set("v.objData", newData);
        cmp.set("v.enableInfiniteLoading", false);
        cmp.set("v.loadedRows", newData.length);
        cmp.set("v.totalRows", newData.length);
      }),
      $A.getCallback(function (error) {
        console.log("fetchData promise finished with errors: " + error.message);
      })
    );
  },

  //retrieve columns
  getColumns: function (cmp, event) {
    var action = cmp.get("c.getColumns");
    var useStandard = cmp.get("v.useStandard");

    action.setParams({
      useStandard: useStandard
    });

    var dataPromise = this.executeAction(cmp, action);

    return dataPromise.then(
      $A.getCallback(function (result) {
        var parsedResult = JSON.parse(result);
        cmp.set("v.objColumns", parsedResult);
      }),
      $A.getCallback(function (error) {
        console.log(
          "getColumns promise finished with errors: " + error.message
        );
      })
    );
  },

  initComponent: function (cmp, event) {
    this.getColumns(cmp, event);
  }
});