-- Extract Publishers
COPY publisher_05(publisherid,publisher_name,country) 
TO 'folder_path\publisher_05.csv' DELIMITER ',' CSV;

--Extract Books
COPY book_05(ISBN,Title,Pub_year,Price) 
TO 'folder_path\book_05.csv' DELIMITER ',' CSV;

--Extract Book-Publisher Relationships
COPY book_05(ISBN,publisherid) 
TO 'folder_path\book_publisher_05.csv' DELIMITER ',' CSV;

--Extract Reviews: Only the first 10000 reviews were queried. They were ordered to ensure compatibility with next query
COPY (select ReviewID,Review_Timestamp,Score from review_05 ORDER BY ReviewID limit 10000)
TO 'folder_path\review_05.csv' DELIMITER ',' CSV;

--Extract Review-Book relationship: Only the first 10000 reviews were queried. The same 10000 as in the last query thanks to ORDER BY
COPY (select ReviewID,BookISBN from review_05 ORDER BY ReviewID limit 10000)
TO 'folder_path\review_book_05.csv' DELIMITER ',' CSV;

--Extract Authors: Only the first 15000 authors were queried. They were ordered to ensure compatibility with next query
COPY (select * from author_05 ORDER BY authorid limit 15000)
TO 'folder_path\author_05.csv' DELIMITER ',' CSV;

--Extract Author-Book relationship: Only queried the relationships that refer to the 15000 authors from the last query
COPY (select creation_05.authorid, bookisbn, author_role 
	  from creation_05, (
	  SELECT authorid
	  from author_05
	  order by authorid
	  limit 15000
	  ) as x
	  where creation_05.authorid=x.authorid
	  ORDER BY creation_05.authorid 
	  )
TO 'folder_path\author_book_05.csv' DELIMITER ',' CSV;

-- Extract Users
COPY user_05(user_name,e-mail,real_name) 
TO 'folder_path\user_05.csv' DELIMITER ',' CSV;

-- Extract Orders
COPY order_05(order_id,user_name,delivery_address,placement_timestamp,completion_timestamp) 
TO 'folder_path\order_05.csv' DELIMITER ',' CSV;

-- Extract Book-Order relationships
COPY order_05(order_id,bookisbn) 
TO 'folder_path\order_book_05.csv' DELIMITER ',' CSV;
