@isTest
private class DummyDataSource_Test {
	static testmethod void dummyTest(){
		Account acct = new Account(name = 'apex test account');
		insert acct;
		
		DummyDataSource dds = new DummyDataSource();
		dds.init(acct);
		
		System.assertEquals('DummyDataSource',dds.getName() );
		System.assertEquals('A sample dummy plugin',dds.getLabel() );
		System.assertEquals('/img/alohaSkin/feeds/cloud.png',dds.getImageURL() );
		System.assertEquals(1,dds.getEvents().size() );
	}
}