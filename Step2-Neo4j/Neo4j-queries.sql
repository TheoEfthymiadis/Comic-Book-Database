--Books from publishers with Headquarters in France along with their Authors
match (a:Publisher)-[r:publishes]->(b:Book)<-[k:authored]-(c:Author)
where a.Publisher_Country='France'
return b,c

--Users with at least 5 orders in a decending list ordered by their number of orders
match (a:User) 
where size((a)-[:placed]->())>4 
return a, size((a)-[:placed]->()) as count 
order by count desc