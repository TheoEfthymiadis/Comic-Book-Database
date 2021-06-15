import gzip
import json
import pandas as pd
import numpy as np
import uuid
import os
import datetime
import calendar
import sys

current_path = sys.path[0]
destination_path = current_path + "\\data-import.sql"

with gzip.open(current_path + "\\goodreads_books_comics_graphic.json.gz", "r") as f:
    data = f.read()


# Pre-processing of String
my_new_string_value = data.decode("utf-8")
my_new_string_value = my_new_string_value.replace("}\n{", "},\n{")
my_new_string_value = '{"Books":['+my_new_string_value + ']}'
data = 0    # discard to save RAM



# Load to json
my_json = json.loads(my_new_string_value)
my_new_string_value = 0   # discard to save RAM



# List of interesting dictionary keys
interesting_columns = ['isbn', 'isbn13', 'description', 'authors', 'publisher', 'publication_year', 'title', 'book_id']

# List of the dictionary keys that will be dropped
drop_keys = []

# Remove unnecessary dictionary keys and values
for key in my_json['Books'][0]:
    if key not in interesting_columns:
        drop_keys.append(key)

for j in my_json['Books']:
    for i in drop_keys:
        j.pop(i, None)

# Removing all books that don't have ISBN and ISBN13
books_faulty = []   # List to count faulty books that should be removed
books_clean = []    # New list to store the books that will be used
publishers = []     # List to store all publishers for later


for i, j in enumerate(my_json['Books']):
    if (((j['isbn'] == np.nan) | (j['isbn'] == '') | (j['isbn'] == ' ') | (not j['isbn'].strip())) &
            ((j['isbn13'] == np.nan) | (j['isbn13'] == '') | (j['isbn13'] == ' ') | (not j['isbn13'].strip()))):
        books_faulty.append(i)
    else:
        books_clean.append(j)
        publishers.append(j['publisher']) # Gathering all publishers in one list

# Use first 10 digits of ISBN13 to fill ISBN where possible
for i, j in enumerate(books_clean):
    if ((j['isbn'] == np.nan) | (j['isbn'] == '') | (j['isbn'] == ' ') | (not j['isbn'].strip())):
        j['isbn'] = j['isbn13'][3:]
    j.pop('isbn13', None)

my_json = 0     # Drop to save RAM

print('Faulty Books (no ISBN and no ISBN13) =    ' + str(len(books_faulty)))
print('Clean Books=   '+str(len(books_clean)))

books_faulty = 0     # Drop to save RAM

# Removing quotes from description, title and publisher
for j in books_clean:
    j['description'] = j['description'].replace('''"''', '''''').replace("""'""", """""")
    j['publisher'] = j['publisher'].replace('''"''', '''''').replace("""'""", """""")
    j['title'] = j['title'].replace('''"''', '''''').replace("""'""", """""")
    if len(j['title']) > 200:
        j['title'] = j['title'][0:200] # Title can be maximum 200 characters
    if len(j['publication_year']) > 4:
        j['publication_year'] = "NULL" # Publication Year has more than 4 characters


# -------------------------------------FINISH BOOK PRE-PROCESSING-------------------------------------------------------

# Select the Unique Publishers
publishers_set = set(publishers)
unique_publishers = list(publishers_set)

# Create dictionary with publisher:publisher_id
publisher_dict = {}

for publisher in unique_publishers:
    publisher_id = uuid.uuid4()
    publisher_dict[publisher] = publisher_id

publisher_dict.pop('', None) # discarding the empty key

publishers = 0    # drop to save RAM
publishers_set = 0  # drop to save RAM
unique_publishers = 0   # drop to save RAM

# Remove quotes from Publisher Names
corrected_publisher_dict = {k.replace('''"''', '''''').replace("""'""", """"""): v for k, v in publisher_dict.items()}

publisher_dict = 0  # Drop to save RAM

# -------------------------------------FINISH PUBLISHER PRE-PROCESSING--------------------------------------------------

# Write the PUBLISHER_05 INSERT INTO statements
filedata = """TRUNCATE PUBLISHER_05 CASCADE;\nINSERT INTO PUBLISHER_05(publisherid,publisher_name) VALUES"""

with open(destination_path, 'w', encoding="utf-8") as file:
    file.write(filedata)
    for i, j in enumerate(corrected_publisher_dict):
        if i != 0:
            file.write(',')
        file.write(f"""\n('{corrected_publisher_dict[j]}', '{j}')""")
    file.write('\n;')
file.close()

# Write the BOOK_05 INSERT INTO statements
filedata = """\nTRUNCATE BOOK_05 CASCADE;"""

# Define the batch size for books
length = len(books_clean)
batch_size = 1000

number_of_batches = int(length/batch_size) + 1

batch_list = [batch_size*i for i in range(0, number_of_batches)]
batch_list.append(length)

with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)

    # CREATING THE BATCHES
    for index, batch in enumerate(batch_list[1:]):
        file.write("""\nINSERT INTO BOOK_05(isbn,title,pub_year,publisherid,price,description) VALUES""")
        books_batch = books_clean[batch_list[index]:batch_list[index+1]]

        # ITERATING OVER EACH BATCH
        for i, j in enumerate(books_batch):
            if i != 0:
                file.write(',')
            if j['publisher'] != '':
                pub_id = "'" + str(corrected_publisher_dict[j['publisher']]) + "'"
            else:
                pub_id = "NULL"

            price = max(10, np.random.normal(70, 20))   # Generate random book price: normal distribution (mean = 70,std = 20)
            formatted_string = "{:.2f}".format(price)
            float_value = float(formatted_string)

            file.write(f"""\n('{j['isbn']}','{j['title']}','{j['publication_year']}', {pub_id},{float_value},'{j['description']}')""")
        file.write('\n;')

file.close()

# ---------------------------------------------- LOAD AUTHORS ----------------------------------------------------------
with gzip.open(current_path + "\\goodreads_book_authors.json.gz", "r") as f:
   data = f.read()

#Preprocessing
my_new_string_value = data.decode("utf-8")
my_new_string_value = my_new_string_value.replace("}\n{", "},\n{")
my_new_string_value = '{"Authors":['+my_new_string_value + ']}'

data = 0   # discard to save RAM

#Load JSON as Dictionary
my_json = json.loads(my_new_string_value)
interesting_columns = ['author_id', 'name']

my_new_string_value = 0  # discard to save RAM

# Dropping non interesting keys
authors_exp = my_json['Authors']

my_json = 0 # discard to save RAM

drop_keys = []
for key in authors_exp[0]:
    if key not in interesting_columns:
        drop_keys.append(key)

for j in authors_exp:
    for i in drop_keys:
        j.pop(i, None)

# Remove brackets inside strings and entries with author name longer than 100 characters
for j, i in enumerate(authors_exp):
    i['name'] = i['name'].replace('''"''', '''''')
    i['name'] = i['name'].replace("""'""", """""")
    if (len(i['name']) > 100):
        i['name'] = i['name'][0:100]   # Only keep first 100 characters of author name


authors_df = pd.DataFrame(authors_exp)

# Create dictionary with Author_ID:Author_UUID
author_id_dict = {}

for i in authors_df['author_id']:
    author_uuid = uuid.uuid4()
    author_id_dict[i] = author_uuid

author_id_dict.pop('', None) # discarding the empty key

authors_df = []    # drop to save RAM


# Write the INSERT TO statements for 05_AUTHOR

filedata = """truncate AUTHOR_05 CASCADE;\n"""

# Define the batch size for authors
length = len(authors_exp)
batch_size = 1000

number_of_batches = int(length/batch_size) + 1

batch_list = [batch_size*i for i in range(0, number_of_batches)]
batch_list.append(length)


with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)
    for index, batch in enumerate(batch_list[1:]):
        file.write("""INSERT INTO AUTHOR_05(authorid,author_name) VALUES\n""")
        authors_batch = authors_exp[batch_list[index]:batch_list[index+1]]
        for i in authors_batch[:-1]:
            id_string = author_id_dict[i['author_id']]
            name_string = i['name']
            file.write(f"""('{id_string}','{name_string}'),\n""")
        id_string = author_id_dict[authors_batch[-1]['author_id']]
        name_string = authors_batch[-1]['name']
        file.write(f"""('{id_string}','{name_string}')\n;\n""")

file.close()

# Write the INSERT TO statements for 05_CREATION

# Define the batch size for books
length = len(books_clean)
batch_size = 250

number_of_batches = int(length/batch_size) + 1

batch_list = [batch_size*i for i in range(0, number_of_batches)]
batch_list.append(length)
# -----------------

filedata = """\nTruncate CREATION_05 CASCADE;"""
comma_counter = 0    # parameter to assist with the comma insertions

with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)

    # CREATING BATCHES
    for index, batch in enumerate(batch_list[1:]):
        file.write("""\nINSERT INTO CREATION_05(authorid,BookIsbn,author_role) VALUES""")
        books_batch = books_clean[batch_list[index]:batch_list[index+1]]

        comma_counter = 0
        # ITERATING OVER ONE BATCH
        for i, j in enumerate(books_batch[:-1]):
            isbn = j['isbn']
            for k in j['authors']:
                comma_counter = comma_counter + 1
                if comma_counter != 1:
                    file.write(',')
                author_id = author_id_dict[k['author_id']]
                if k['role'] == '':
                    author_role = 'NULL'
                else:
                    author_role = "'" + str(k['role']).replace('''"''', '''''').replace("""'""", """""") + "'" # removing quotes
                file.write(f"""\n('{author_id}','{isbn}',{author_role})""")

        # Last member of the Batch
        for k in books_batch[-1]['authors']:
            comma_counter = comma_counter + 1
            if comma_counter != 1:
                file.write(',')
            isbn = books_batch[-1]['isbn']
            author_id = author_id_dict[k['author_id']]
            if k['role'] == '':
                author_role = 'NULL'
            else:
                author_role = "'" + str(k['role']).replace('''"''', '''''').replace("""'""", """""") + "'"  # removing quotes

            file.write(f"""\n('{author_id}','{isbn}',{author_role})""")

        file.write('\n;') # Closing of the Batch
file.close()

author_id_dict = {}   # Drop to save ram
authors_exp = []      # Drop to save ram
authors_batch = []    # Drop to save ram

book_id_to_isbn = {}  # Dictionary to map BookID to ISBN

for i in books_clean:
    book_id_to_isbn[i['book_id']] = i['isbn']

# ---------------------------------------------------------------------------------------------------------------------
with gzip.open(current_path + "\\goodreads_reviews_comics_graphic.json.gz", "r") as f:
    data = f.read()

# Pre-processing of String
my_new_string_value = data.decode("utf-8")
my_new_string_value = my_new_string_value.replace("}\n{", "},\n{")
my_new_string_value = '{"Reviews":['+my_new_string_value + ']}'

# Load to json
my_json = json.loads(my_new_string_value)
reviews_exp = my_json['Reviews']

# List of interesting dictionary keys
interesting_columns = ['book_id', 'review_id', 'rating', 'date_added', 'review_text']


# List of the dictionary keys that will be dropped
drop_keys = []

# Remove unnecessary dictionary keys and values
for key in reviews_exp[0]:
    if key not in interesting_columns:
        drop_keys.append(key)

for j in reviews_exp:
    for i in drop_keys:
        j.pop(i, None)

# Write the REVIEW_05 INSERT INTO statements
filedata = """\nTRUNCATE REVIEW_05 CASCADE;"""

# Define the batch size for books
length = len(reviews_exp)
batch_size = 2000

number_of_batches = int(length/batch_size) + 1

batch_list = [batch_size*i for i in range(0, number_of_batches)]
batch_list.append(length)
comma_support_counter = 0

with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)

    # CREATING THE BATCHES
    for index, batch in enumerate(batch_list[1:]):
        file.write("""\nINSERT INTO REVIEW_05(ReviewID,Review_Timestamp,Review_Body,Score,BookISBN) VALUES""")
        reviews_batch = reviews_exp[batch_list[index]:batch_list[index+1]]
        comma_support_counter = 0

        # ITERATING OVER EACH BATCH
        for i, j in enumerate(reviews_batch):

            if j['book_id'] not in book_id_to_isbn.keys():
                continue
            comma_support_counter = comma_support_counter + 1
            if comma_support_counter != 1:
                file.write(',')

            review_id = uuid.uuid4()

            review_body = j['review_text'].replace('''"''', '''''').replace("""'""", """""")

            score = int(j['rating'])
            if ((score < 1) | (score > 5)):
                score = 'NULL'

            bookisbn = book_id_to_isbn[j['book_id']]


            review_time = j['date_added']
            rev_time_str = str(list(calendar.month_abbr).index(review_time[4:7]))+ '/' + review_time[8:10]  + \
                            '/' + review_time[26:30] + ' ' + review_time[11:13] + ':' + review_time[14:16] + ':' + \
                           review_time[17:19] + ' ' + review_time[20:25]
            element = datetime.datetime.strptime(rev_time_str, "%m/%d/%Y %H:%M:%S %z")

            file.write(f"""\n('{review_id}','{element}','{review_body}',{score},'{bookisbn}')""")
        file.write('\n;')

file.close()

users = pd.read_excel(current_path + "\\Comic_Book_Users_Orders.xlsx",  sheet_name='Users')
orders = pd.read_excel(current_path + "\\Comic_Book_Users_Orders.xlsx",  sheet_name='Orders')

users['user_addressess'] = 'a'
users['user_addressess'] = users['user_addressess'] .astype('object')

for i in range(len(users)):
    x = [users.iloc[int(i)][5], users.iloc[int(i)][6], users.iloc[int(i)][7]]
    users.at[int(i),'user_addressess']  = x

users = users.drop(labels = ['User_Address1', 'User_Address2', 'User_Address3'], axis = 1)

# ############ WRITE USER_05 INSERT STATEMENTS
filedata = """truncate USER_05 CASCADE;\nINSERT INTO USER_05(User_Name,User_Password,Email,Real_Name,Phone_Number) VALUES\n"""

with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)
    for i in users.index:
        if i != 0:
            file.write(',\n')
        file.write(f"""('{users.at[i,'User_Name']}','{users.at[i,'User_Password']}','{users.at[i,'Email']}','{users.at[i,'Real_Name']}','{users.at[i,'Phone_Number']}')""")

    file.write('\n;')

file.close()

# ############ WRITE USER_ADDRESS_05 INSERT STATEMENTS
filedata = """\ntruncate USER_ADDRESS_05 CASCADE;\nINSERT INTO USER_ADDRESS_05(User_Name,User_Address) VALUES\n"""
comma_support_counter = 0

with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)

    for i in users.index:

        for j, k in enumerate(users.at[i, 'user_addressess']):
            if k == '-':
                continue
            comma_support_counter = comma_support_counter + 1
            if comma_support_counter != 1:
                file.write(',\n')
            file.write(f"""('{users.at[i, 'User_Name']}','{k.replace('"', '')}')""")
    file.write('\n;')

file.close()

# ############ WRITE ORDER_05 INSERT STATEMENTS
filedata = """\ntruncate ORDER_05 CASCADE;\nINSERT INTO ORDER_05(BookISBN,User_Name,Delivery_Address,Placement_Timestamp,Completion_Timestamp) VALUES\n"""

# Write the INSERT TO statements for 05_AUTHOR
with open(destination_path, 'a', encoding="utf-8") as file:
    file.write(filedata)
    for i in orders.index:
        if i != 0:
            file.write(',\n')
        if orders.at[i, 'Completion_Timestamp'] != '-':
            completion = "'"+str(datetime.datetime.strptime(orders.at[i, 'Completion_Timestamp'], "%m/%d/%Y %H:%M:%S %z"))+"'"
        else:
            completion = 'NULL'

        placement = datetime.datetime.strptime(orders.at[i, 'Placement_Timestamp'], "%m/%d/%Y %H:%M:%S %z")
        file.write(f"""('{orders.at[i,'ISBN']}','{orders.at[i,'User_Name']}','{orders.at[i,'Delivery_Address']}','{placement}',{completion})""")

    file.write('\n;')

file.close()
