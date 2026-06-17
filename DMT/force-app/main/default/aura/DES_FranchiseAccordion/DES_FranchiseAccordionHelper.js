({

  helperFun: function (component, event, secId) {
    var acc = document.getElementById('first_' + secId);
    $A.util.toggleClass(acc, 'slds-hide');
    var acc2 = document.getElementById('second_' + secId);
    $A.util.toggleClass(acc2, 'slds-hide');
  },

  helperFunTable: function (component, event, secId) {
    var acc = document.getElementById('third_' + secId);
    this.toggleClass(acc, 'slds-hide');
  },

  toggleClass: function (element, className) {
    if (element != null) {
      if (!this.hasClass(element, className))
        this.addClass(element, className);
      else
        this.removeClass(element, className);
    }

  },

  addClass: function (element, className) {
    element.classList.add(className);
  },

  removeClass: function (element, className) {
    element.classList.remove(className);
  },

  hasClass: function (element, className) {
    return element != null && element.classList.contains(className);
  },

})