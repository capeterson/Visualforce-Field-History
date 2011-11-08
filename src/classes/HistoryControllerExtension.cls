public with sharing class HistoryControllerExtension{
		public History thisHistory {get; set;}
		
		public HistoryControllerExtension(ApexPages.StandardController sc){
			sObject thisObject = sc.getRecord();
			thisHistory = new History(thisObject,false);
			thisHistory.buildEntries();
			thisHistory.invertList();
		}
		
		public HistoryControllerExtension(){
			id currentId = ApexPages.currentPage().getParameters().get('id');
			sObject thisObject = sObjectUtils.getAllFields(currentId);
			thisHistory = new History(thisObject,false);
			thisHistory.buildEntries();
			thisHistory.invertList();
		}
}