# Atliq-Supply-Chain-Analysis
This repository contains the complete workflow for building a data-driven Supply Chain Performance Dashboard for Atliq Mart. The project involves preparing SQL views for key metrics, loading curated datasets into Power BI, and creating an interactive dashboard for tracking On-Time, In-Full, and OTIF delivery KPIs, along with Line and Volume fill rates. The goal is to support operational visibility and data-backed decision-making in supply chain performance monitoring.

## 📁 Dataset Overview
The following folders organize the datasets, SQL queries and dashboard used in this project:

### 1. raw_datasets/
orders.csv, order_lines.csv, targets.csv: Original raw datasets provided for order-level and line-level delivery information, as well as target KPIs per customer.

### 2. sql_queries/
sql_views_creation.sql: SQL scripts used to create modular views for each key visual and KPI card in Power BI. It includes modeling with SQL joins for constructing cleaned and joined fact and dimension tables.

## 3. atliq_supply_chain_dashboard/
Atliq_Supply_Chain_Dashboard.pbix: Final Power BI dashboard that includes monthly OTIF KPIs, fill rates, and product-level delivery insights. Built using DAX measures, slicers, bookmarks, and interactive area charts. The dashboard supports dynamic filtering and drill-downs via Power BI data modeling.

---

## 📚 More Information
For detailed documentation and project notes, refer to the Notion workspace:

👉 [View Full Project Details on Notion](https://www.notion.so/AtliQ-Mart-Supply-Chain-Analysis-2261279cd9ac80828d74fd7068cce3e2?source=copy_link)

---

## 🔗 Dataset Source

The original raw dataset used in this project can be found on Code Basics:

📥 [Atliq Mark Supply Chain Dataset on Code Basics](https://codebasics.io/challenges/codebasics-resume-project-challenge/5)
