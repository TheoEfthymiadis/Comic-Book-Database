To run this part of the project, both PostgreSQL and Python are required

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

The following steps can be used to reproduce the workflow:
1) Clone the repository to a local folder
2) Install PostgreSQL
3) Connect to PostgreSQL and create a new, empty database (we will refer to it as [Your Database name])
4) Feed the schema.sql file to PostgreSQL to create a new relational schema
- Open the CMD
- SET PGCLIENTENCODING=utf-8
- chcp 65001
- psql -U postgres –f "local_folder_path\schema.sql" [Your Database name]


5) Download the data sets with authors, books and book revies from the following links:

goodreads_books_comics_graphic.json.gz:
https://drive.google.com/uc?id=1ICk5x0HXvXDp5Zt54CKPh5qz1HyUIn9m

goodreads_reviews_comics_graphic.json.gz:
https://drive.google.com/uc?id=1V4MLeoEiPQdocCbUHjR_7L9ZmxTufPFe

goodreads_book_authors.json.gz:
https://drive.google.com/uc?id=19cdwyXwfXx_HDIgxXaHzH0mrx8nMyLvC

Move these files to your cloned repository. Do not unzip them!

6) Run the parser.py script. This parser will read the three files along with the 
Comic_Book_Users_Orders.xlsx file and generate a new file named: 'data-import.sql'.
This file contains the postgreSQL statements to feed the data into the database.

7) Feed the data-import.sql file to PostgreSQL in order to import the data to the DB

- psql -U postgres –f "local_folder_path\data-import.sql" [Your Database name]

8) Execute potential queries, such as the ones stored in the sample-queries.sql file.
