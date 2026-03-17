# 🏥 Healthcare Patient Analytics Dashboard

> An end-to-end data analytics project using MySQL Workbench and Microsoft Power BI,
> analyzing 55,500 patient records to build a leadership-ready dashboard.

## 📁 Project Files
| File | Description |
|------|-------------|
| `healthcare_analytics.sql` | MySQL Workbench script: table setup, data load, computed columns, 25+ queries, 3 views |
| `Patient_Utilization_Dashboard.pbix` | Power BI dashboard: 4 pages, 25+ visuals, KPIs, DAX measures |

## 🛠️ Tools Used
- **MySQL 8.0 + MySQL Workbench** — Data storage, computed columns, aggregation queries
- **Microsoft Power BI Desktop** — Interactive 4-page dashboard
- **DAX** — Custom KPI measures, YoY calculations, rate metrics

## 📊 Dataset
- **55,500 patient records** | 15 columns | Date range: May 2019 – May 2024
- Columns: Name, Age, Gender, Blood Type, Medical Condition, Admission Date,
  Doctor, Hospital, Insurance Provider, Billing Amount, Room Number,
  Admission Type, Discharge Date, Medication, Test Results

## 📋 Dashboard Pages
| Page | Focus |
|------|-------|
| 1 - Executive Summary | KPI cards, monthly trend, admission types, condition breakdown |
| 2 - Demographics | Gender, age groups, blood types, condition-age heatmap |
| 3 - Utilization | Stacked area trend, day-of-week, LOS trend, capacity planning |
| 4 - Financial | Revenue waterfall, billing by insurer, test outcomes |

## 🔑 Key SQL Features
- Computed columns: `length_of_stay`, `age_group`, `billing_tier`
- 3 optimised MySQL Views for direct Power BI import
- 25+ queries across demographics, utilization, financials, provider analysis
