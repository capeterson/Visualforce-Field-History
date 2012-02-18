@isTest
private class ChatterTrackingDataSource_Test {
	static testmethod void accountTest(){
		Account acct = new Account(name = 'apex test account');
		insert acct;
		DataSource.Provider provider = new ChatterTrackingDataSource();
		provider.init(acct);
		
		System.assertEquals(ChatterTrackingDataSource.PROVIDER_NAME,provider.getName());
		System.assertEquals(ChatterTrackingDataSource.PROVIDER_LABEL,provider.getLabel());
		System.assertEquals(ChatterTrackingDataSource.IMAGE_URL,provider.getImageURL());
		
		
		//we should really insert some chatter events if possible
		
		provider.getEvents();
		
	}
}