# Building an AI-Powered Energy Simulation: A Deep Dive into the Google Cloud Ecosystem with Gemini and BigQuery

This directory contains the SQL scripts used in the Medium article: **"Building an AI-Powered Energy Simulation: A Deep Dive into the Google Cloud Ecosystem with Gemini and BigQuery"**.

## 📌 Project Overview
This project demonstrates how to build an AI-powered energy simulation system leveraging the Google Cloud ecosystem, specifically focusing on data processing in BigQuery and orchestration with Gemini.

## 🛠️ BigQuery Code Snippets

### 1. Data Cleaning & Integrity Check
Before analyzing energy efficiency, this query ensures data integrity by safely converting current and potential energy efficiency scores into integers, gracefully handling any non-numeric anomalies.

- **File**: `bq_queries.sql`
- **Key Function**: `SAFE_CAST`

### 2. Renovation Roadmap Generation
This query concentrates multiple recommended improvements for a single property into a sequential, chronological "Roadmap" string, visualizing the logical steps for energy efficiency upgrades.

- **File**: `bq_queries.sql`
- **Key Function**: `STRING_AGG`

## 🚀 How to Use
1. Replace `your_project.dataset.table` and `your_project.recommendations_table` with your actual BigQuery table paths.
2. Run the queries in the BigQuery SQL Workspace.
