# Data Dictionary

## sales (62,884 rows)
| Column | Type | Description |
|--------|------|-------------|
| order_number | int | Unique order ID |
| line_item | int | Line number within order |
| order_date | date | Date order was placed |
| delivery_date | date | Date delivered (null for in-store) |
| customer_key | int | Foreign key to customers |
| store_key | int | Foreign key to stores (0 = Online) |
| product_key | int | Foreign key to products |
| quantity | int | Units purchased |

## customers (15,266 rows)
| Column | Type | Description |
|--------|------|-------------|
| customer_key | int | Primary key |
| gender | str | Male / Female |
| name | str | Full name |
| city | str | City |
| state_code | str | State/province code |
| country | str | Country |
| continent | str | Continent |
| birthday | date | Date of birth (DD/MM/YYYY) |

## products (2,517 rows)
| Column | Type | Description |
|--------|------|-------------|
| product_key | int | Primary key |
| product_name | str | Full product name |
| brand | str | Brand |
| color | str | Color |
| unit_cost_usd | float | Cost per unit |
| unit_price_usd | float | Selling price per unit |
| subcategory | str | Subcategory |
| category | str | Category (8 total) |

## stores (67 rows)
| Column | Type | Description |
|--------|------|-------------|
| store_key | int | Primary key (0 = Online) |
| country | str | Country |
| state | str | State |
| square_meters | float | Store size (null for Online) |
| open_date | date | Opening date |
