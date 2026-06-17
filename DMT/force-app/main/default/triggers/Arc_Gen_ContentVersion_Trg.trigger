trigger Arc_Gen_ContentVersion_Trg on ContentVersion (after insert) {
    new Arc_Gen_ContentVersion_TrgHandler().run(Trigger.new);
}