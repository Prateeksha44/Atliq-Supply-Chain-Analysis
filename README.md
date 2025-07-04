# Atliq-Supply-Chain-Analysis
This repository contains the complete workflow for building a data-driven Supply Chain Performance Dashboard for Atliq Mart. The project involves preparing SQL views for key metrics, loading curated datasets into Power BI, and creating an interactive dashboard for tracking On-Time, In-Full, and OTIF delivery KPIs, along with Line and Volume fill rates. The goal is to support operational visibility and data-backed decision-making in supply chain performance monitoring.

Dataset Overview
The following folders organize the datasets and SQL assets used in this project:

1. raw_datasets/
orders.csv, order_lines.csv, targets.csv: Original raw datasets provided for order-level and line-level delivery information, as well as target KPIs per customer.

2. sql_queries/
sql_views_creation.sql: SQL scripts used to create modular views for each key visual and KPI card in Power BI.

fact_dim_modeling.sql: SQL joins for constructing cleaned and joined fact and dimension tables.

eda_queries.sql: Exploratory SQL used to understand data patterns, delivery gaps, and inconsistencies.

📊 Power BI Dashboard
📁 atliq_supply_chain_dashboard/
AtliQ_Supply_Chain_Dashboard.pbix: Final Power BI dashboard that includes:

Monthly On-Time, In-Full, and OTIF KPIs

Fill rate metrics (Volume & Line)

Product delivery trends and performance breakdowns

Dynamic bookmarks and slicers for interactive exploration

Power BI techniques include:

KPI cards with DAX measures and color logic

Area charts with sparklines

Page navigation using bookmarks and arrow shapes

Slicers and filters for customer/product selection

Modeling relationships for dynamic drill-downs

📚 More Information
For detailed documentation, design decisions, and project notes, refer to the Notion workspace:

👉 View Full Project on Notion

🧮 Tools Used
PostgreSQL: SQL-based data preparation and view creation

Power BI: Dashboard building and interactive DAX-based visuals

Notion: Project documentation and reflection
