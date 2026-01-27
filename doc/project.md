## What is lists?
- Every User will contain many List.
- Each List has user_id which is the id of the User it belongs to.
- Each List has 2 important fields: type - public or private & private - boolean.

## What is list_items?
- Every List will contain many ListItem, which is nothing but TV Shows or Movies (from TMDB). In other words, a wrapper around TMDB item.
- Each ListItem has an item_id and item_type (tv_show or movie etc).
- Each ListItem has list_id which is the id of the List it belongs to.
