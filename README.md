# Financial Services Analytics

## Overview

An end-to-end financial services analytics project that analyzes investment performance, customer acquisition, customer satisfaction, and loan risk over five years (2022–2026).

The project uses synthetic data to generate business insights through SQL and an interactive Streamlit dashboard.

## Tech Stack

- **Database:** PostgreSQL
- **Programming:** Python, Pandas, NumPy
- **Analytics:** SQL
- **Dashboard:** Streamlit, Plotly
- **Environment:** Jupyter Notebook, VS Code

## Project Structure

```text
financial-services-analytics/
├── data/
├── notebooks/
│   └── data_generation.ipynb
├── sql/
│   ├── 01_create_tables.sql
│   └── 02_aggregate_tables.sql
├── app.py
├── business_inference.md
├── README.md
└── requirements.txt
```

## Key KPIs

1. Assets Under Management (AUM)
2. Investment Return (ROI)
3. Customer Acquisition Cost (CAC)
4. Net Promoter Score (NPS)
5. Loan Default Rate
6. Customer Acquisition by Channel

## Setup and Execution

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Create the database

Create a PostgreSQL database named `financial_services_db` and execute:

```bash
psql -U postgres -d financial_services_db -f sql/01_create_tables.sql
```

### 3. Generate sample data

Run `notebooks/data_generation.ipynb` to generate five years of synthetic data and export the datasets as CSV files into the `data/` directory.

### 4. Load data

Load the generated CSV files into their corresponding PostgreSQL tables.

### 5. Create aggregate tables

Execute:

```bash
psql -U postgres -d financial_services_db -f sql/02_aggregate_tables.sql
```

### 6. Launch the dashboard

Configure the database connection in `app.py`, then run:

```bash
streamlit run app.py
```

## Dashboard Features

- Institution selection
- Interactive date-range filter
- Quarterly KPI trends
- Investment and lending performance analysis
- Customer acquisition channel breakdown

## Business Insights

Refer to [business_inference.md](business_inference.md) for key observations, business interpretations, and recommendations.

## Note

All data used in this project is synthetically generated for analytical and demonstration purposes.