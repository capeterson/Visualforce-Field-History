public with sharing class DataSource {
	/**
	 * This interface represents a source of some kind of history data. Standard implementations include:
	 * - Chatter field history tracking
	 * - Boring old field history tracking
	 * - Related object creation
	 * 
	 * Custom data sources can be used by the Timeline class by implementing this interface
	 * and calling it's addProvider method. 
	 
	 * Implementations of the Provider interface should not rely on having their constructor called!
	 **/
	public interface Provider{
		String getName();
		String getLabel();
		List<DataSource.Event> getEvents();
		/**
		 * Providers may be instantiated dynamically at runtime and in this case the constructor is never called.
		 * in these cases the init method will be called instead. You should ideally just call init from your constructor
		 * and do all variable initialization in this method.
		 * @author capeterson
		 **/
		void init(sObject subject);
	}
	
	/**
	 * A generic implementation of an event object. May be extended by providers,
	 * or may be used as is if no custom behavior is needed.
	**/
	public virtual class Event{
		protected String target; //the field or related object being operated on
		protected DateTime timestamp;
		protected String description;
		protected Id actor;
		protected List<Provider> dataProviders;
		protected String detailURL;
		
		protected Event(){}
		
		public Event(Provider provider, DateTime timestamp, String description, Id actor, String detailUrl){
			this.dataProviders = new List<Provider>{ provider };
			this.timestamp = timestamp;
			this.description = description;
			this.actor = actor;
			this.detailURL = detailURL;
		}
		
		public virtual String getTarget(){
			return target;
		}
		public virtual DateTime getTimestamp(){
			return timestamp;
		}
		public virtual String getLocalizedTimestamp(){
			return timestamp.format();
		}
		public virtual String getDescription(){
			return description;
		}
		public virtual Id getActorId(){
			return actor;
		}
		public virtual String getDetailURL(){
			return detailURL;
		}
		public virtual Set<String> getProviderNames(){
			Set<String> result = new Set<String>();
			for(DataSource.Provider p: dataProviders)
				result.add(p.getName());
			return result;
		}
		public virtual Set<String> getProviderLabels(){
			Set<String> result = new Set<String>();
			for(DataSource.Provider p: dataProviders)
				result.add(p.getLabel());
			return result;
		}
		
		 
	}
	
}