To run this part of the project, PostgreSQL, Python and Neo4j are required

Python 3 libraries requirements

Package		Version		Latest Version
1OS		0.1		0.1
gzippy		0.1.2		0.1.2
numpy		1.19.2		1.19.4
pandas		1.1.3		1.1.5
python-dateutil	2.8.1		2.8.1
pytz		2020.1		2020.4
setuptools	40.8.0		51.0.0
six		1.15.0		1.15.0

You also need a stable version of PostgreSQL
https://www.postgresql.org/download/

You also need a stable version of Neo4j
https://neo4j.com/

It is assumed that the process described in Step1-PostgreSQL folder of the repository was executed first.
Compared to what was described in step1, some adjustments were made to both the schema and the data.
That's why there are new sql files and python parsers here to resmble those changes

The following steps can be used to reproduce the workflow:
1) Clone the repository to a local folder (if not done in step1)
2) Install PostgreSQL (if not done in step1)
3) Feed the newschema.sql file to PostgreSQL to create an adjusted version of the relational schema
4) Download the data sets with authors, books and book revies from the following links (if not done in step1):

goodreads_books_comics_graphic.json.gz:
https://drive.google.com/uc?id=1ICk5x0HXvXDp5Zt54CKPh5qz1HyUIn9m

goodreads_reviews_comics_graphic.json.gz:
https://drive.google.com/uc?id=1V4MLeoEiPQdocCbUHjR_7L9ZmxTufPFe

goodreads_book_authors.json.gz:
https://drive.google.com/uc?id=19cdwyXwfXx_HDIgxXaHzH0mrx8nMyLvC

Move these files to the Step2-Neo4j folder of your cloned repository. Do not unzip them!

5) Run the newparser.py script. This parser will read the three files along with the 
Comic_Book_Users_Orders2.xlsx file, as well as the CH_Nationality_List_20171130_v1.csv file
and generate a new file named: 'newdata.sql'.
This file contains the updated postgreSQL statements to feed the data into the adjusted database.

6) Feed the newdata.sql file to PostgreSQL in order to import the data to the PostgreSQL DB
7) Extract the Data from the PostgreSQL data base as individual .csv files per table.
In order to do that, you have to run the sql commands described in PostgreSQL-export.sql.
However, the local folder path of the Neo4j folder has to be provided. For instance, the first command is:

COPY publisher_05(publisherid,publisher_name,country) 
TO 'folder_path\publisher_05.csv' DELIMITER ',' CSV;

In the second line, the first part of the output file name, 'folder_path' has to be replaced with your local folder
path and the final output will be stored in 'local_folder_path\publisher_05.csv'.
By repeating this process, 10 individual .csv files will be created, ready for import to Neo4j.

8) Install Neo4j and upload the 10 .csv files that were created in step 7 to the Neo4j server.
9) Execute the commands listed in Neo4j-import.sql file to create the nodes and relationships of the graph.
It's vital that the commands are executed from top to bottom. The order matters!
10) Execute sample queries, such as the ones listed in the Neo4j-queries.sql file.

Finally, it's worth noting that the 2 reports inside the folder provide some insight on the rationale behind design choices:
-Graph-Design.pdf
-sample-graph-queries.pdf

