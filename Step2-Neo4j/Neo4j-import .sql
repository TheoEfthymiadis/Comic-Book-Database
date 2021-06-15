
#Import Publishers
LOAD CSV FROM 'file:///publisher_05.csv' AS line with line where (line[0] is not null AND line[1] is not null AND line[2] is not null)
create(a:Publisher{id:line[0],Publisher_Name:line[1],Publisher_Country:line[2]})

#Import Books (17mins long)
LOAD CSV FROM 'file:///book_05.csv' AS line with line where (line[0] is not null AND line[1] is not null AND line[3] is not null) 
create(a:Book{Book_ISBN:line[0],Book_Name:line[1],Publication_Year:line[2],Price:line[3]})


#Import Book-Publisher Relationship (51min long)
:auto USING PERIODIC COMMIT 2000
LOAD CSV FROM 'file:///book_publisher_05.csv' AS line with line where (line[0] is not null AND line[1] is not null) 
match(a:Book{Book_ISBN:line[0]}) 
match(b:Publisher{id:line[1]}) 
create (b)-[:publishes]->(a)  

#Import Reviews
:auto USING PERIODIC COMMIT 2000
LOAD CSV FROM 'file:///review_05.csv' AS line with line where (line[0] is not null AND line[1] is not null AND line[2] is not null)
create(a:Review{id:line[0],Review_Timestamp:line[1],Score:line[2]})

#Import Book-Review Relationship
:auto USING PERIODIC COMMIT 2000 
LOAD CSV FROM 'file:///review_book_05.csv' AS line with line where (line[0] is not null AND line[1] is not null) 
match(a:Book{Book_ISBN:line[1]}) 
match(b:Review{id:line[0]}) 
create (b)-[:describes]->(a)  

#Import Authors
:auto USING PERIODIC COMMIT 2000
LOAD CSV FROM 'file:///author_05.csv' AS line with line where (line[0] is not null AND line[1] is not null)
create(a:Author{id:line[0],author_name:line[1],gender:line[2],nationality:line[3]})

#Import Book-Author Relationship
:auto USING PERIODIC COMMIT 2000 
LOAD CSV FROM 'file:///author_book_05.csv' AS line with line where (line[0] is not null AND line[1] is not null) 
match(a:Book{Book_ISBN:line[1]}) 
match(b:Author{id:line[0]}) 
CREATE (b)-[:authored{role:line[2]}]->(a)  

#Import Users
LOAD CSV FROM 'file:///user_05.csv' AS line with line where (line[0] is not null AND line[1] is not null AND line[2] is not null)
create(a:User{User_Name:line[0],email:line[1],Real_name:line[2]})

#Import Orders
LOAD CSV FROM 'file:///order_05.csv' AS line with line where (line[0] is not null AND line[1] is not null AND line[2] is not null AND line[3] is not null)
create(a:Order{order_id:line[0],user_name:line[1],delivery_address:line[2], placement_timestamp:line[3], completion_timestamp:line[4]})


#Creating User-Order relationships (no need for import)
match(a:User) 
match(b:Order)
where a.User_Name = b.user_name
CREATE (a)-[:placed]->(b)  

#Import book-order relationship
LOAD CSV FROM 'file:///order_book_05.csv' AS line with line where (line[0] is not null AND line[1] is not null) 
match(a:Book{Book_ISBN:line[1]}) 
match(b:Order{order_id:line[0]}) 
CREATE (b)-[:includes_book]->(a) 

