# Data Pipeline
 
A data pipeline script is made up of a few sections:
 1. Set the common variables (lots of boilerplate)
 2. Define a bunch of config files that use these variables
 3. Tell Azure to Initialise all the infrastructure you'll need, including:
	- A Resource Group (to gather your infrastructure under a heading, so you can kill it all easily later)
	- A (blob/data lake) storage account
	- A SQL Server (this is true infrastructure)
	- A Data Factory (this is more of a gathering place for jobs)
	- Note: You could potentially do the above in parallel
 4. Grab the details of the infrastructure, and pass the details to Data Factory. Details include:
	- Linked services templates, specifying, for example:
		- Storage Linked Services, telling Data Factory where your Blob storage is
		- SQL DB Linked services
		- HDInsight services, and so on
	- To manage the private keys (effectively passwords) that get produced when you create a service, the script replaces a parameter in these template files with the real key when it runs, and writes the version with the real key to a temporary folder
	


