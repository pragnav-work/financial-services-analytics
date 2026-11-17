
import os
import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from dotenv import load_dotenv

load_dotenv()

st.set_page_config(
    page_title="Financial Services Analytics",
    layout="wide"
)

st.title("Financial Services Analytics Dashboard")


# Database connection
@st.cache_resource
def get_engine():
    connection_url = URL.create(
        "postgresql+psycopg2",
        username=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=os.getenv("DB_NAME")
    )
    return create_engine(connection_url)


@st.cache_data
def load_data(query):
    with get_engine().connect() as connection:
        return pd.read_sql_query(query, connection)


# Load institution names
institutions = load_data("""
    SELECT DISTINCT institution_name
    FROM institutions
    ORDER BY institution_name
""")

selected_institution = st.selectbox(
    "Select Institution",
    institutions["institution_name"]
)

# Load aggregate tables
queries = {
    "AUM": "SELECT * FROM agg_monthly_aum",
    "ROI": "SELECT * FROM agg_monthly_roi",
    "CAC": "SELECT * FROM agg_monthly_cac",
    "NPS": "SELECT * FROM agg_monthly_nps",
    "Loan Default": "SELECT * FROM agg_monthly_loan_default",
    "Customer Acquisition": "SELECT * FROM agg_monthly_customer_acquisition"
}

data = {}

for name, query in queries.items():
    df = load_data(query)
    df["report_month"] = pd.to_datetime(df["report_month"])

    data[name] = df[
        df["institution_name"] == selected_institution
    ].copy()


# DATE RANGE FILTER

st.subheader("Dashboard Filters")

min_date = data["AUM"]["report_month"].min().date()
max_date = data["AUM"]["report_month"].max().date()

date_range = st.date_input(
    "Select Date Range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date
)

if len(date_range) == 2:
    start_date, end_date = date_range
elif len(date_range) == 1:
    start_date = end_date = date_range[0]
else:
    start_date, end_date = min_date, max_date


for name in data:
    df = data[name]

    data[name] = df[
        (df["report_month"].dt.to_period("M") >= pd.Period(start_date, freq="M")) &
        (df["report_month"].dt.to_period("M") <= pd.Period(end_date, freq="M"))
    ].copy()


if any(df.empty for df in data.values()):
    st.warning("No data available for the selected date range.")
    st.stop()


# QUARTERLY DATA

def add_quarter(df):
    df = df.copy()
    df["quarter"] = df["report_month"].dt.to_period("Q").astype(str)
    return df


aum = add_quarter(data["AUM"])
roi = add_quarter(data["ROI"])
cac = add_quarter(data["CAC"])
nps = add_quarter(data["NPS"])
loans = add_quarter(data["Loan Default"])
acquisition = add_quarter(data["Customer Acquisition"])


# AUM and ROI: latest monthly snapshot in each quarter
quarterly_aum = (
    aum.sort_values("report_month")
    .groupby("quarter")
    .tail(1)
)

quarterly_roi = (
    roi.sort_values("report_month")
    .groupby("quarter")
    .tail(1)
)


# CAC
quarterly_cac = (
    cac.groupby("quarter", as_index=False)
    .agg(
        total_expense=("total_acquisition_expense", "sum"),
        new_customers=("new_customers", "sum")
    )
)

quarterly_cac["cac"] = (
    quarterly_cac["total_expense"] /
    quarterly_cac["new_customers"].replace(0, pd.NA)
)


# NPS
nps["weighted_score"] = nps["nps_score"] * nps["total_responses"]

quarterly_nps = (
    nps.groupby("quarter", as_index=False)
    .agg(
        total_responses=("total_responses", "sum"),
        weighted_score=("weighted_score", "sum")
    )
)

quarterly_nps["nps_score"] = (
    quarterly_nps["weighted_score"] /
    quarterly_nps["total_responses"]
)


# Loan default rate
quarterly_loans = (
    loans.groupby("quarter", as_index=False)
    .agg(
        total_loans=("total_loans", "sum"),
        defaulted_loans=("defaulted_loans", "sum")
    )
)

quarterly_loans["default_rate"] = (
    quarterly_loans["defaulted_loans"] /
    quarterly_loans["total_loans"] * 100
)


# Customer acquisition
channel_columns = [
    "online_customers",
    "branch_customers",
    "referral_customers",
    "social_media_customers"
]

quarterly_acquisition = (
    acquisition.groupby("quarter", as_index=False)[
        ["new_customers"] + channel_columns
    ].sum()
)


# KPI CARDS

st.subheader("Key Performance Indicators")

latest_aum = quarterly_aum.iloc[-1]
latest_roi = quarterly_roi.iloc[-1]

total_expense = cac["total_acquisition_expense"].sum()
total_new_customers = cac["new_customers"].sum()

overall_cac = (
    total_expense / total_new_customers
    if total_new_customers > 0 else 0
)

overall_nps = (
    (nps["nps_score"] * nps["total_responses"]).sum()
    / nps["total_responses"].sum()
)

total_loans = loans["total_loans"].sum()
total_defaults = loans["defaulted_loans"].sum()

overall_default_rate = (
    total_defaults / total_loans * 100
    if total_loans > 0 else 0
)

total_acquired = acquisition["new_customers"].sum()

col1, col2, col3 = st.columns(3)

col1.metric("Latest AUM", f"₹{latest_aum['total_aum']:,.0f}")
col2.metric("Latest ROI", f"{latest_roi['roi_percentage']:.2f}%")
col3.metric("Customer Acquisition Cost", f"₹{overall_cac:,.0f}")

col4, col5, col6 = st.columns(3)

col4.metric("Overall NPS", f"{overall_nps:.2f}")
col5.metric("Loan Default Rate", f"{overall_default_rate:.2f}%")
col6.metric("New Customers", f"{total_acquired:,}")


# CHARTS

st.divider()
st.subheader("Performance Trends")


def show_line_chart(df, x, y, title, y_label):
    fig = px.line(
        df,
        x=x,
        y=y,
        markers=True,
        title=title,
        labels={
            x: "Quarter",
            y: y_label
        }
    )

    fig.update_layout(
        height=350,
        hovermode="x unified",
        margin=dict(l=20, r=20, t=60, b=20)
    )

    st.plotly_chart(fig, use_container_width=True)


show_line_chart(
    quarterly_aum, "quarter", "total_aum",
    "Assets Under Management (AUM)", "AUM (₹)"
)

show_line_chart(
    quarterly_roi, "quarter", "roi_percentage",
    "Investment Return (ROI)", "ROI (%)"
)

show_line_chart(
    quarterly_cac, "quarter", "cac",
    "Customer Acquisition Cost", "CAC (₹)"
)

show_line_chart(
    quarterly_nps, "quarter", "nps_score",
    "Customer Satisfaction (NPS)", "NPS Score"
)

show_line_chart(
    quarterly_loans, "quarter", "default_rate",
    "Loan Default Rate", "Default Rate (%)"
)


# Customer Acquisition by Channel

st.divider()
st.subheader("Customer Acquisition by Channel")

channel_data = quarterly_acquisition.melt(
    id_vars="quarter",
    value_vars=channel_columns,
    var_name="channel",
    value_name="customers"
)

channel_data["channel"] = channel_data["channel"].replace({
    "online_customers": "Online",
    "branch_customers": "Branch",
    "referral_customers": "Referral",
    "social_media_customers": "Social Media"
})

fig = px.bar(
    channel_data,
    x="quarter",
    y="customers",
    color="channel",
    barmode="stack",
    title="Quarterly Customer Acquisition by Channel",
    labels={
        "quarter": "Quarter",
        "customers": "New Customers",
        "channel": "Acquisition Channel"
    }
)

fig.update_layout(
    height=400,
    hovermode="x unified",
    margin=dict(l=20, r=20, t=60, b=20)
)

st.plotly_chart(fig, use_container_width=True)
