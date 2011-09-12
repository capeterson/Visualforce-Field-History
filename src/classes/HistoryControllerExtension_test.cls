@isTest
private class HistoryControllerExtension_test {
	static testmethod void extensionTest(){
		Contact con = new Contact(LastName = 'apex test');
		insert con;
		ApexPages.StandardController sc = new ApexPages.StandardController(con);
		HistoryControllerExtension controllerExt = new HistoryControllerExtension(sc);
		System.assertNotEquals(controllerExt.thisHistory,null);
	}
	
	static testmethod void controllerTest(){
		Contact con = new Contact(LastName = 'apex test');
		insert con;
		PageReference testPage = Page.History;
		testPage.getParameters().put('id',con.id);
		Test.setCurrentPage(testPage);
		
		HistoryControllerExtension controllerExt = new HistoryControllerExtension();
		System.assertNotEquals(controllerExt.thisHistory,null);
	}
}