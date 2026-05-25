# 🚚 Supply Chain & Logistics Performance Dashboard

<div align="center">

![Supply Chain](https://img.shields.io/badge/Domain-Supply%20Chain%20%26%20Logistics-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-success?style=for-the-badge)
![Records](https://img.shields.io/badge/Records%20Analyzed-180%2C519-orange?style=for-the-badge)

**Excel → Python → SQL Server → Power BI**

*An end-to-end analytics project uncovering $36.8M worth of delivery failures across 23 global regions*

</div>

---

## 🔴 The Business Problem

> A global e-commerce company is losing customer trust and revenue — but **nobody knows exactly where, why, or how badly.**

Logistics managers had no single view of delivery performance. Orders were being shipped, but:
- Were they arriving **on time?**
- Were they arriving **complete?**
- Which **regions** were failing most?
- Which **shipping modes** were worth the cost?

**Without answers, every decision was a guess.**

---

## ✅ The Solution

Built a **4-page interactive Power BI dashboard** backed by a fully engineered SQL Server data warehouse — giving logistics managers a single source of truth to isolate bottlenecks, quantify failures, and prioritize corrective action.

```
Raw CSV (180K rows)
      ↓
  Excel Audit          → Schema validation, null checks, pivot discovery
      ↓
  Python (pandas)      → KPI flag engineering, EDA, clean data export
      ↓
  SQL Server           → Star schema, 6 KPI views, SLA breach analysis
      ↓
  Power BI Dashboard   → 4-page interactive report with drill-down slicers
```

---

## 💥 Key Findings That Changed Everything

| # | Finding | Impact |
|---|---------|--------|
| 🔴 1 | **First Class shipping: 100% SLA breach rate** across all 23 regions | Customers paying premium price receive the worst service |
| 🔴 2 | **Overall OTD rate: only 40.9%** vs 85% industry benchmark | Less than half of all orders arrive on time |
| 🔴 3 | **South of USA ranks 2nd worst globally** at 39.5% OTD | Regional bottleneck confirmed, actionable by logistics team |
| 🔴 4 | **Perfect Order Rate: 14%** — 86% of orders have at least one failure | On-time + complete + undamaged + accurate docs |
| 🔴 5 | **OTD never exceeded 45% in any month across 36 months** | Structural failure, not a temporary disruption |

---

## 📊 Dashboard Pages

### Page 1 — Executive Summary
> *"What is our overall supply chain health?"*

- 7 KPI scorecards (OTD, OTIF, SLA Breach, Perfect Order, Revenue, Profit, Avg Days to Ship)
- Side-by-side bar charts comparing OTD vs SLA Breach by shipping mode
- Color-coded performance indicators (Red / Orange / Green)
- Key finding callout box

### Page 2 — Regional Analysis
> *"Which regions are failing and by how much?"*

- All 23 global regions ranked by OTD rate (worst → best)
- Interactive slicers: filter by Year (2015/2016/2017) and Shipping Mode
- Color-coded regional performance table with 6 KPIs per region
- South of USA and Central Africa highlighted as critical regions

### Page 3 — SLA Heatmap
> *"Which region + shipping mode combination is most broken?"*

- 23 × 4 matrix heatmap (Regions × Shipping Modes)
- Red = Critical (≥80% breach) | Orange = High Risk | Green = Acceptable
- Entire First Class column is Red across all 23 regions
- At-a-glance identification of worst combinations

### Page 4 — Trend Analysis
> *"Has performance improved over time?"*

- 36-month OTD vs SLA Breach trend lines (2015–2017)
- Monthly order volume bar chart
- Perfect Order Rate trend vs 85% industry benchmark line
- Answer: **No improvement — flat lines confirm structural problem**

---

## 🛠️ Technical Architecture

### Star Schema Design
```
                    DIM_Date
                       │
DIM_Customer ──── FACT_Orders ──── DIM_Shipping
                       │
              DIM_Region   DIM_Product
                       │
                  DIM_Geography
```

### KPI Engineering (Python + SQL)
```python
# KPI flags engineered as binary columns (0/1)
is_on_time       = 1 if delivery_status in ['Advance shipping', 'Shipping on time']
is_complete      = 1 if order_status == 'COMPLETE'
is_sla_breach    = 1 if days_shipping_real > days_shipping_scheduled
is_otif          = is_on_time AND is_qty_fulfilled
is_perfect_order = is_on_time AND is_complete AND NOT is_sla_breach
days_variance    = days_shipping_real - days_shipping_scheduled
```

### SQL KPI Views Built
```sql
VW_KPI_Summary          -- Overall KPI scorecards
VW_KPI_By_ShippingMode  -- Performance by shipping mode
VW_KPI_By_Region        -- Regional breakdown with year/mode filters
VW_SLA_Heatmap          -- 23×4 region × shipping mode matrix
VW_Monthly_Trend        -- 36-month time series (2015-2017)
VW_KPI_By_Category      -- Product category performance
```

---

## 📈 KPI Definitions

| KPI | Definition | Our Result | Benchmark |
|-----|-----------|------------|-----------|
| **OTD** | % orders delivered on time | 40.9% | 85%+ |
| **OTIF** | % on time AND complete quantity | 40.9% | 90%+ |
| **SLA Breach** | % shipments exceeding promised days | 57.3% | <15% |
| **Perfect Order** | On-time + complete + undamaged + accurate docs | 14.0% | 80%+ |
| **Fill Rate** | % of order quantity fulfilled immediately | 100% | 95%+ |
| **Avg Days to Ship** | Average actual shipping days | 3.5 days | 2-3 days |
| **Days Variance** | Actual days minus promised days | +0.6 days late | ≤0 |

---

## 🗂️ Project Structure

```
supply-chain-logistics-dashboard/
│
├── 📁 Excel/
│   └── Working_Data.csv              # 25-column audited working dataset
│
├── 📁 Python/
│   ├── Supply_chain_Data_Cleaning_and_EDA.ipynb  # Full cleaning + EDA notebook
│   ├── supplychain_clean.csv         # 37-column engineered clean dataset
│   ├── plot1_delay_by_shipmode.png   # OTD vs predicted risk chart
│   ├── plot2_delay_by_region.png     # Regional OTD bar chart
│   └── plot3_sla_heatmap.png         # Region × Shipping Mode heatmap
│
├── 📁 SQL/
│   ├── 01_create_database.sql        # SupplyChainDB setup
│   ├── 02_staging_table.sql          # 37-column staging table
│   ├── 03_bulk_insert.sql            # CSV import + validation
│   ├── 04_dimension_tables.sql       # Star schema dimensions
│   ├── 05_fact_table.sql             # FACT_Orders with foreign keys
│   ├── 06_rebuild_dim_region.sql     # Fan trap fix
│   ├── 07_validation.sql             # Data quality checks
│   ├── 08_kpi_views.sql              # All 6 KPI views
│   └── 09_view_verification.sql      # View row count verification
│
├── 📁 Power BI file/
│   └── Supply_chain_Dashboard.pbix   # Full 4-page dashboard
│
├── 📁 Screenshots/
│   ├── page1_executive_summary.png
│   ├── page2_regional_analysis.png
│   ├── page3_sla_heatmap.png
│   └── page4_trend_analysis.png
│
└── README.md
```

---

## ⚙️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| **Microsoft Excel** | 365 | Data audit, null checks, pivot validation |
| **Python** | 3.12 | Cleaning, KPI engineering, EDA visualizations |
| **pandas** | 2.x | Data transformation and flagging |
| **seaborn / matplotlib** | latest | EDA charts and heatmaps |
| **SQL Server Express** | 2019 | Star schema, views, T-SQL analytics |
| **SSMS** | 22 | Query development and schema management |
| **Power BI Desktop** | latest | 4-page interactive dashboard |
| **DAX** | — | Calculated columns and KPI measures |

---

## 🚀 How to Reproduce

### Prerequisites
- SQL Server Express (free) + SSMS
- Python 3.8+ with pandas, matplotlib, seaborn
- Power BI Desktop (free)
- DataCo Supply Chain Dataset from [Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

### Steps
```bash
# Step 1: Run SQL scripts in order (01 → 09)
# in SSMS against your SQL Server instance

# Step 2: Run Python notebook
jupyter notebook "Python/Supply_chain_Data_Cleaning_and_EDA.ipynb"

# Step 3: Open Power BI file
# Power BI file/Supply_chain_Dashboard.pbix
# Update SQL Server connection string to your instance
```

---

## 💡 Business Recommendations

Based on the analysis, three immediate actions would improve OTD from 40.9% toward the 85% benchmark:

1. **Investigate First Class SLA commitments** — 100% breach rate suggests promised delivery windows are unachievable. Either renegotiate carrier SLAs or adjust customer-facing promises.

2. **Priority intervention in South of USA and Central Africa** — both regions sit below 40% OTD. Route optimization or carrier substitution could yield measurable improvement within one quarter.

3. **Root cause analysis on Standard Class performance** — Standard Class is the best performer at 57.7% OTD despite being the lowest-cost option. Understanding why could unlock improvements across other modes.

---

## 👤 Author

**Loknadh Venkata Krishna Sai Kona**

[![GitHub](https://img.shields.io/badge/GitHub-KrishnaSai315-black?style=flat&logo=github)](https://github.com/KrishnaSai315)

---

<div align="center">

*Built with real-world data | End-to-end analytics pipeline | Portfolio project*

⭐ Star this repo if you found it useful

</div>
