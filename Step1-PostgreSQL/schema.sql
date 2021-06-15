DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
CREATE EXTENSION pgcrypto;

--- Table with Reviews
CREATE TABLE public.REVIEW_05 (
    ReviewID UUID DEFAULT public.gen_random_uuid() NOT NULL,
    Review_Timestamp TIMESTAMPTZ,
    Nickname VARCHAR(40),
    Review_Body TEXT,
    Score INT,
	CHECK (Score >= 1 AND Score <= 5),
    BookISBN CHAR(10),
    CONSTRAINT pk_REVIEW PRIMARY KEY (
        ReviewID	
     )
);


--- Table with Books
CREATE TABLE public.BOOK_05 (
    ISBN CHAR(10),
    Description TEXT DEFAULT 'There is no available description for this book',
    Price NUMERIC(5,2) NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Pub_Year CHAR(4),
    PublisherID UUID,
    CONSTRAINT pk_BOOK PRIMARY KEY (
        ISBN
     )
);

ALTER TABLE public.BOOK_05 
    ALTER COLUMN Pub_Year SET DEFAULT NULL;

---Insert TRIGGER TO CHECK ISBN UNIQUNENESS in the Books table
CREATE FUNCTION book_insert_isbn_filter() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
   IF EXISTS(SELECT 1 FROM BOOK_05 WHERE isbn = NEW.isbn)
	THEN
      RAISE NOTICE 'Skipping row with ISBN=% and Title=%',
         NEW.isbn, NEW.title;
      RETURN NULL;
	ELSE
      RETURN NEW;
  	END IF;
END;$$;

CREATE TRIGGER book_isbn_insert_filter
   BEFORE INSERT ON BOOK_05 FOR EACH ROW
   EXECUTE PROCEDURE book_insert_isbn_filter();

   
---Insert TRIGGER TO REPLACE EMPTY BOOK DESCRIPTIONS in the Books table

CREATE FUNCTION book_insert_description_filter() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
	IF CHAR_LENGTH(NEW.description) = 0 THEN
  		NEW.description := 'There is no available description for this book';
		RETURN NEW;
	ELSE
		RETURN NEW;
	END IF;
END;$$;

CREATE TRIGGER book_description_insert_filter
   BEFORE INSERT ON BOOK_05 FOR EACH ROW
   EXECUTE PROCEDURE book_insert_description_filter();


---Insert TRIGGER TO REPLACE EMPTY Publication Years in the Books table
CREATE FUNCTION book_insert_pub_year_filter() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
	IF CHAR_LENGTH(NEW.pub_year) = 0 THEN
  		NEW.pub_year := NULL;
		RETURN NEW;
	ELSE
		RETURN NEW;
	END IF;
END;$$;

CREATE TRIGGER book_pub_year_insert_filter
   BEFORE INSERT ON BOOK_05 FOR EACH ROW
   EXECUTE PROCEDURE book_insert_pub_year_filter();




---Table with the Publishers
CREATE TABLE public.PUBLISHER_05 (
    PublisherID UUID DEFAULT public.gen_random_uuid() NOT NULL,
    Publisher_Name VARCHAR(100),
    Country VARCHAR(30),
    Address VARCHAR(60),
    Phone VARCHAR(15),
    CONSTRAINT pk_PUBLISHER PRIMARY KEY (
        PublisherID
     )
);


---Table with the Authors
CREATE TABLE public.AUTHOR_05 (
    AuthorID UUID DEFAULT public.gen_random_uuid() NOT NULL,
    Author_Name VARCHAR(100),
    Gender CHAR(1),
    CHECK (Gender = 'F' OR Gender = 'M'),
    Nationality VARCHAR(15),
    CONSTRAINT pk_AUTHOR PRIMARY KEY (
        AuthorID
     )
);


---Table to combine authors with books -> Role of each author in the creation of each book
CREATE TABLE public.CREATION_05 (
    AuthorID UUID,
    BookISBN CHAR(10),
    Author_Role VARCHAR(100),
    CONSTRAINT pk_CREATE PRIMARY KEY (
        AuthorID,BookISBN
     )
);


---INSERT TRIGGER TO CHECK Author Role Length
CREATE FUNCTION creation_insert_role_filter() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
   IF (LENGTH(NEW.author_role) > 100)
	THEN
      RAISE NOTICE 'Author role too long. Skipping row with ISBN=% and Role=%',
         NEW.bookisbn, NEW.author_role;
      RETURN NULL;
	ELSE
      RETURN NEW;
  	END IF;
END;$$;

CREATE TRIGGER creation_role_insert_filter
BEFORE INSERT ON CREATION_05 FOR EACH ROW
EXECUTE PROCEDURE creation_insert_role_filter();



--- INSERT TRIGGER TO CHECK ISBN+Authorid UNIQUNENESS in the Creation table
CREATE FUNCTION creation_insert_isbn_author_filter() RETURNS trigger
   LANGUAGE plpgsql AS
$$BEGIN
   IF EXISTS(SELECT 1 FROM CREATION_05 WHERE (bookisbn = NEW.bookisbn AND authorID = NEW.authorid))
	THEN
      RAISE NOTICE 'Combination of ISBN + Authorid already exists. Skipping row with ISBN=% and Authorid=%',
         NEW.bookisbn, NEW.authorid;
      RETURN NULL;
	ELSE
      RETURN NEW;
  	END IF;
END;$$;

CREATE TRIGGER creation_isbn_author_insert_filter
   BEFORE INSERT ON CREATION_05 FOR EACH ROW
   EXECUTE PROCEDURE creation_insert_isbn_author_filter();


---Table with e-shop Users
CREATE TABLE public.USER_05 (
    User_Name VARCHAR(30) NOT NULL,
    User_Password VARCHAR(20) NOT NULL,
    Email VARCHAR(30) UNIQUE  NOT NULL,
    Real_Name VARCHAR(40)  NOT NULL,
    Phone_Number VARCHAR(15) NOT NULL,
    CONSTRAINT pk_USER PRIMARY KEY (
        User_Name
     )
);


---Table with e-shop Orders
CREATE TABLE public.ORDER_05 (
    Order_id UUID DEFAULT public.gen_random_uuid() NOT NULL,
    BookISBN CHAR(10),
    User_Name VARCHAR(30),
    Delivery_Address VARCHAR(60)   NOT NULL,
    Placement_Timestamp TIMESTAMPTZ,
    Completion_Timestamp TIMESTAMPTZ,
    CONSTRAINT pk_ORDER PRIMARY KEY (
        Order_id
     )
);
ALTER TABLE public.ORDER_05 
    ALTER COLUMN Completion_Timestamp SET DEFAULT NULL;


---Table to store Multiple user Addresses per user
CREATE TABLE USER_ADDRESS_05 (
    User_Name VARCHAR(30),
    User_Address VARCHAR(60) NOT NULL,
    CONSTRAINT pk_USER_ADDRESS PRIMARY KEY (
        User_Name,User_Address
     )
);


---Introduction of Foreign Key constraints
ALTER TABLE public.REVIEW_05 ADD CONSTRAINT fk_REVIEW_BookISBN FOREIGN KEY(BookISBN)
REFERENCES public.BOOK_05 (ISBN);

ALTER TABLE public.BOOK_05 ADD CONSTRAINT fk_BOOK_PublisherID FOREIGN KEY(PublisherID)
REFERENCES public.PUBLISHER_05 (PublisherID);

ALTER TABLE public.CREATION_05 ADD CONSTRAINT fk_CREATION_AuthorID FOREIGN KEY(AuthorID)
REFERENCES public.AUTHOR_05 (AuthorID);

ALTER TABLE public.CREATION_05 ADD CONSTRAINT fk_CREATION_BookISBN FOREIGN KEY(BookISBN)
REFERENCES public.BOOK_05 (ISBN);

ALTER TABLE public.ORDER_05 ADD CONSTRAINT fk_ORDER_BookISBN FOREIGN KEY(BookISBN)
REFERENCES public.BOOK_05 (ISBN);

ALTER TABLE public.ORDER_05 ADD CONSTRAINT fk_ORDER_UserName FOREIGN KEY(User_Name)
REFERENCES public.USER_05 (User_Name);

ALTER TABLE public.USER_ADDRESS_05 ADD CONSTRAINT fk_USER_ADDRESS_UserName FOREIGN KEY(User_Name)
REFERENCES public.USER_05 (User_Name);

