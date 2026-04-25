# IT Asset & Procurement Management System

A full-stack ITAM web app built with Flask + MySQL.

## Setup

### 1. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 2. Create the database

Open MySQL Workbench and run the migration scripts in order:

```
01_create_db.sql
02_create_tables.sql  (or however your schema files are numbered)
...
08_migrate_to_final.sql
```

### 3. Seed the database

In MySQL Workbench, run:

```
seed_data.sql
```

### 4. Configure credentials

Edit `config.py` and set your MySQL root password:

```python
DB_PASSWORD = 'your_password_here'
```

### 5. Run the app

```bash
python app.py
```

Open [http://localhost:5000](http://localhost:5000) in your browser.

## Pages

| URL | Page |
|-----|------|
| `/` | Dashboard |
| `/assets` | Asset Management |
| `/vendors` | Vendor Directory |
| `/purchase-orders` | Purchase Orders |
| `/employees` | Employee Directory |

## API

All REST endpoints are available at `http://localhost:5000/api/...`

Key endpoints:
- `GET/POST /api/assets`
- `GET/PUT/DELETE /api/assets/<id>`
- `GET/POST /api/vendors`
- `GET/POST /api/purchase-orders`
- `POST /api/goods-receipts`
- `GET/POST /api/employees`
- `GET /api/dashboard/stats`
