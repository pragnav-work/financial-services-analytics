
-- Remove existing aggregate tables before rebuilding
DROP TABLE IF EXISTS agg_monthly_customer_acquisition;
DROP TABLE IF EXISTS agg_monthly_loan_default;
DROP TABLE IF EXISTS agg_monthly_nps;
DROP TABLE IF EXISTS agg_monthly_cac;
DROP TABLE IF EXISTS agg_monthly_roi;
DROP TABLE IF EXISTS agg_monthly_aum;


-- 1. Monthly Assets Under Management (AUM)
CREATE TABLE agg_monthly_aum AS
SELECT
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', ip.snapshot_date)::DATE AS report_month,
    SUM(ip.market_value) AS total_aum
FROM investment_performance ip
JOIN investment_accounts ia
    ON ip.account_id = ia.account_id
JOIN customers c
    ON ia.customer_id = c.customer_id
JOIN institutions i
    ON c.institution_id = i.institution_id
GROUP BY
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', ip.snapshot_date);


-- 2. Monthly Investment ROI
CREATE TABLE agg_monthly_roi AS
SELECT
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', ip.snapshot_date)::DATE AS report_month,
    SUM(ip.invested_amount) AS total_invested,
    SUM(ip.market_value) AS total_market_value,
    ROUND(
        (
            (SUM(ip.market_value) - SUM(ip.invested_amount))
            / NULLIF(SUM(ip.invested_amount), 0)
        ) * 100,
        2
    ) AS roi_percentage
FROM investment_performance ip
JOIN investment_accounts ia
    ON ip.account_id = ia.account_id
JOIN customers c
    ON ia.customer_id = c.customer_id
JOIN institutions i
    ON c.institution_id = i.institution_id
GROUP BY
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', ip.snapshot_date);


-- 3. Monthly Customer Acquisition Cost (CAC)
CREATE TABLE agg_monthly_cac AS
WITH monthly_expenses AS (
    SELECT
        institution_id,
        DATE_TRUNC('month', expense_date)::DATE AS report_month,
        SUM(expense_amount) AS total_acquisition_expense
    FROM acquisition_expenses
    GROUP BY
        institution_id,
        DATE_TRUNC('month', expense_date)
),
monthly_customers AS (
    SELECT
        institution_id,
        DATE_TRUNC('month', acquisition_date)::DATE AS report_month,
        COUNT(*) AS new_customers
    FROM customers
    GROUP BY
        institution_id,
        DATE_TRUNC('month', acquisition_date)
)
SELECT
    i.institution_id,
    i.institution_name,
    e.report_month,
    e.total_acquisition_expense,
    COALESCE(c.new_customers, 0) AS new_customers,
    ROUND(
        e.total_acquisition_expense /
        NULLIF(c.new_customers, 0),
        2
    ) AS cac
FROM monthly_expenses e
JOIN institutions i
    ON e.institution_id = i.institution_id
LEFT JOIN monthly_customers c
    ON e.institution_id = c.institution_id
    AND e.report_month = c.report_month;


-- 4. Monthly Net Promoter Score (NPS)
CREATE TABLE agg_monthly_nps AS
SELECT
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', cs.survey_date)::DATE AS report_month,
    COUNT(*) AS total_responses,
    ROUND(
        (
            COUNT(*) FILTER (WHERE cs.nps_rating >= 9)::NUMERIC
            -
            COUNT(*) FILTER (WHERE cs.nps_rating <= 6)::NUMERIC
        ) * 100 / NULLIF(COUNT(*), 0),
        2
    ) AS nps_score
FROM customer_surveys cs
JOIN customers c
    ON cs.customer_id = c.customer_id
JOIN institutions i
    ON c.institution_id = i.institution_id
GROUP BY
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', cs.survey_date);


-- 5. Monthly Loan Default Rate
CREATE TABLE agg_monthly_loan_default AS
SELECT
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', la.loan_date)::DATE AS report_month,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (
        WHERE la.loan_status = 'Defaulted'
    ) AS defaulted_loans,
    ROUND(
        COUNT(*) FILTER (
            WHERE la.loan_status = 'Defaulted'
        )::NUMERIC * 100 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate
FROM loan_accounts la
JOIN customers c
    ON la.customer_id = c.customer_id
JOIN institutions i
    ON c.institution_id = i.institution_id
GROUP BY
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', la.loan_date);


-- 6. Monthly Customer Acquisition
CREATE TABLE agg_monthly_customer_acquisition AS
SELECT
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', c.acquisition_date)::DATE AS report_month,
    COUNT(*) AS new_customers,
    COUNT(*) FILTER (
        WHERE c.acquisition_channel = 'Online'
    ) AS online_customers,
    COUNT(*) FILTER (
        WHERE c.acquisition_channel = 'Branch'
    ) AS branch_customers,
    COUNT(*) FILTER (
        WHERE c.acquisition_channel = 'Referral'
    ) AS referral_customers,
    COUNT(*) FILTER (
        WHERE c.acquisition_channel = 'Social Media'
    ) AS social_media_customers
FROM customers c
JOIN institutions i
    ON c.institution_id = i.institution_id
GROUP BY
    i.institution_id,
    i.institution_name,
    DATE_TRUNC('month', c.acquisition_date);
