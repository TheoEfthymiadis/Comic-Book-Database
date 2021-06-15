---a) An SQL query that counts all the comic books in your database
Select count(*) from book_05;

---b) An SQL query that returns the average review score for the comic book with title "Feynman"

select avg(score) 
from review_05, (select isbn from book_05 where title = 'Feynman') as x 
where x.isbn = review_05.bookisbn;

---This query was executed in 3 steps:
---STEP1: (select isbn from book_05 where title = 'Feynman') as x: This internal query returns the isbn of all books with title "Feynman". This selection is 
---   executed before any other heavy computations, like joins. 
---STEP2: where x.isbn = review_05.bookisbn: This part of the query performs a join between the 'ISBN' elements identified in the previous step and the
--- review_05 table. It identifies all reviews that are referring to the books that were returned in step1.
---STEP3:select avg(score) from review_05: This is the last operation that returns the average score for all reviews that were identified in step2.

---c) An SQL query that returns the ISBNs and titles for all books authored by "Alan Moore"

select isbn, title 
from book_05, (
	select bookisbn 
	from creation_05, (

				select authorid 
				from author_05 
				where author_name = 'Alan Moore'
			   ) as x 
	where creation_05.authorid = x.authorid

		) as y 
where y.bookisbn = book_05.isbn; 

---This query was also executed in 3 steps:
---STEP1:select authorid from author_05 where author_name = 'Alan Moore': This part of the query identifies the authorid of 'Alan Moore'
--- this selection query significantly reduces the number of authros that will be used for a join later. It is, therefore, executed first
---STEP2: select bookisbn from creation_05, (STEP1) as x where creation_05.authorid = x.authorid: This query joins the authorid of 'Alan Moore'
--- with the table "CREATION". It identifies the ISBN of all books that were co - authored by 'Alan Moore'.
---STEP3:select isbn, title from book_05, (STEP2) as y where y.bookisbn = book_05.isbn;: This query joins the ISBNs that were identified in 
--- the previous step with the table "BOOK" to identify all books that were co - authored by 'Alan Moore' based on their ISBN. Then, it 
--- performs a projection and only returns the book isbn and title.  

---d)An SQL transaction that modifies a user's order by removing a previous order with a new one of the same user 
---We consider that a new order stored in a new tuple named NEW is inserted to update the old order stored in an old tuple named OLD

---OLD(odrer_id1, bookisbn1, user_name, delivery_address1, Placement_Timestamp1, Completion_Timestamp1)
---NEW(odrer_id2, bookisbn2, user_name, delivery_address2, Placement_Timestamp2, Completion_Timestamp2 := NULL)

BEGIN;

-- Update the BookISBN of the order to account for the user ordering a different book
UPDATE ORDER_05 
SET bookisbn = NEW.bookisbn
WHERE Order_id = OLD.order_id;

-- Update the DeliveryAddress of the order to account for the possibility that the user wants the book delivered to a different address
UPDATE ORDER_05 
SET delivery_address = NEW.delivery_address
WHERE Order_id = OLD.order_id;

-- Update the Placement_Timestamp of the order to account for the new order time placement
UPDATE ORDER_05 
SET Placement_Timestamp = NEW.Placement_Timestamp
WHERE Order_id = OLD.order_id;

-- Update the Completion_Timestamp of the order. It's a new order, not delivered yet so it has to be NULL
UPDATE ORDER_05 
SET Completion_Timestamp := NULL;
WHERE Order_id = OLD.order_id;

-- Now that we uploaded the rest of the attributes, we no longer need the old tuple ID
UPDATE ORDER_05 
SET order_id = NEW.order_id
WHERE Order_id = OLD.order_id;


-- commit the transaction
COMMIT;

