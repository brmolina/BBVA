({ //eslint-disable-line
  doInit: function(component, event, helper) {
    helper.fetchComponentData(component, event, helper);
  },
    
   hideshow: function(component, event, helper) {
    component.find("collapsable").set("v.labelClass","hide");
  },
    sectionOne : function(component, event, helper) {
       helper.helperFun(component,event,'articleOne');
    },
    openActionWindow : function(component, event, helper) {
        window.open("https://reportes.es.igrupobbva/MSTR_WBAM/MicroStrategyCIB/servlet/mstrWeb?Project=ENDG&Port=0&evt=2048001&src=mstrWeb.2048001&documentID=D35F724249EB4C616D9AD7B50DBD43F2&visMode=0&currentViewMedia=2&promptAnswerMode=2&elementsPromptAnswers=81D025BF42DD60224F2B4EA1032D02AC;81D025BF42DD60224F2B4EA1032D02AC:2017%3A10,944E907E4AFABA9D5DB658AB348E8699;944E907E4AFABA9D5DB658AB348E8699:G00000000000404,64138E4E4BC430CD278C5C9E8C80DF1A;64138E4E4BC430CD278C5C9E8C80DF1A:EUR");
        helper.helperFun(component,event,'articleOne');
    },
    openPDF: function(component, event, helper) {
        helper.helperFun(component,event,'articleOne');
    },
 });