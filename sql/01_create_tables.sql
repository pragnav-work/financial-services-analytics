
-- 1. Institutions
CREATE TABLE institutions (
    institution_id UUID PRIMARY KEY,
    institution_name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

-- 2. Products
CREATE TABLE products (
    product_id UUID PRIMARY KEY,
    institution_id UUID REFERENCES institutions(institution_id),
    product_name VARCHAR(100) NOT NULL,
    product_type VARCHAR(20) NOT NULL
        CHECK (product_type IN ('Investment', 'Loan'))
);

-- 3. Customers
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY,
    institution_id UUID REFERENCES institutions(institution_id),
    customer_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    acquisition_date DATE NOT NULL,
    acquisition_channel VARCHAR(50)
);

-- 4. Investment Accounts
CREATE TABLE investment_accounts (
    account_id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id),
    product_id UUID REFERENCES products(product_id),
    opening_date DATE NOT NULL,
    account_status VARCHAR(20) DEFAULT 'Active'
);

-- 5. Investment Performance
CREATE TABLE investment_performance (
    performance_id UUID PRIMARY KEY,
    account_id UUID REFERENCES investment_accounts(account_id),
    snapshot_date DATE NOT NULL,
    invested_amount NUMERIC(15,2) NOT NULL,
    market_value NUMERIC(15,2) NOT NULL,
    UNIQUE (account_id, snapshot_date),
    CHECK (invested_amount > 0),
    CHECK (market_value >= 0)
);

-- 6. Loan Accounts
CREATE TABLE loan_accounts (
    loan_id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id),
    product_id UUID REFERENCES products(product_id),
    loan_amount NUMERIC(15,2) NOT NULL,
    loan_date DATE NOT NULL,
    loan_status VARCHAR(20) NOT NULL
        CHECK (loan_status IN ('Active', 'Repaid', 'Defaulted', 'Closed')),
    CHECK (loan_amount > 0)
);

-- 7. Customer Surveys
CREATE TABLE customer_surveys (
    survey_id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id),
    survey_date DATE NOT NULL,
    nps_rating INTEGER NOT NULL
        CHECK (nps_rating BETWEEN 0 AND 10)
);

-- 8. Acquisition Expenses
CREATE TABLE acquisition_expenses (
    expense_id UUID PRIMARY KEY,
    institution_id UUID REFERENCES institutions(institution_id),
    expense_date DATE NOT NULL,
    expense_type VARCHAR(20) NOT NULL
        CHECK (expense_type IN ('Marketing', 'Sales')),
    expense_amount NUMERIC(15,2) NOT NULL,
    CHECK (expense_amount >= 0)
);
