# Unlocking Real Estate Intelligence: Building an AI-Driven Address Resolution Pipeline with BigQuery, Gemini, and Looker Studio

This directory contains the SQL scripts used in the Medium article: **"Unlocking Real Estate Intelligence: Building an AI-Driven Address Resolution Pipeline with BigQuery, Gemini, and Looker Studio"**.

## 📌 Project Overview
This project establishes a robust, AI-powered data pipeline that resolves, matches, and cleanses disparate UK real estate addresses from two different registries using **BigQuery**, **Gemini 2.5 Flash**, and prepares the data for geo-spatial visualization in **Looker Studio**.

## 🔄 Pipeline Workflow & Architecture
The SQL scripts execute the pipeline through the following stages:

1. **Model Initialization**: Registers the `gemini-2.5-flash` remote model in BigQuery.
2. **Data Staging**: Cleans and prepares Land Registry and EPC raw data.
3. **AI Resolution (Vertex AI)**: Joins datasets by postcode and passes pairs of addresses to Gemini for structured JSON classification.
4. **Data Parsing & Analytics**: Extracts JSON values into formal SQL columns.
5. **Data Mart Preparation**: Deduplicates records and filters time-gap outliers for Looker Studio maps.

## 🚀 How to Use
1. Replace `your-project-id` with your actual Google Cloud Project ID.
2. Ensure you have a valid external connection (`us-central1.gemini-bq-conn`) set up in your BigQuery environment.
3. Run the scripts sequentially.
