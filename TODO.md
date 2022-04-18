# To Do

- MMDB.init(from:) should just read the file directly into the db memory.
- IMplement the rest of the Value types in MMDB
- Write a GeoIPLite2 layer on top of MMDB so the calling code can deal in
  *IP addresses* instead of bits.
- Make some way to leave out branches of a value? Seems wasteful to bring back 
  all that translation data if you just want an ISO country code. Maybe a query
  that takes a 'path' and only returns those branches of maps until exhausted.
  Maybe not, the whole thing has to get parsed anyway.
- Work out an error strategy. I need to make sure a corrupted database can't 
  cause any array out of bounds errors and kill the program.
