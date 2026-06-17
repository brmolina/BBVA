@isTest
private class GBL_HierarchyNodeTest {
  @isTest static void testAll () {
    GBL_HierarchyNode pParent = new GBL_HierarchyNode();
    GBL_HierarchyNode pChild = new GBL_HierarchyNode();

    pParent.label = 'Parent';
    pParent.name = 'ParentName';
    pParent.objectId = 'objectId';
    pParent.objectName = 'objectName';
    pParent.type = 'ParentNode';
    pParent.extendedInfo = 'ExtendedInfo';

    pChild.label = 'Child';
    pChild.name = 'ChildName';
    pChild.objectId = 'objectId';
    pChild.objectName = 'objectName';
    pChild.type = 'ChildNode';

    pParent.children.add(pChild);

    String href = pParent.hRef;
    String labelExtended = pParent.labelExtended;

    System.assertEquals('Parent', pParent.label);
    System.assertEquals('/lightning/r/objectName/objectId/view', pParent.hRef);
    System.assertEquals('Parent (ExtendedInfo)', pParent.labelExtended);
    System.assertEquals(1, pParent.children.size());

    System.assertEquals('Child', pChild.label);
    System.assertEquals('/lightning/r/objectName/objectId/view', pChild.hRef);
    System.assertEquals('Child', pChild.labelExtended);
    System.assertEquals(0, pChild.children.size());
  }
}