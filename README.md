# Call Analysis using PostgreSQL and pgAdmin 4

## Step 1: Setting Up the Environment

### 1. Download and Install pgAdmin 4
- If you haven't installed pgAdmin 4 yet, download it from [pgAdmin's official website](https://www.pgadmin.org/download/).
- Ensure PostgreSQL is installed and configured correctly, as pgAdmin requires a PostgreSQL server.

### 2. Launch pgAdmin 4
- Open pgAdmin 4 and connect to your PostgreSQL server.
- Enter your server credentials (username and password).

### 3. Create a New Database (Optional but Recommended)
- Right-click on the `Databases` node in the left panel.
- Select `Create` > `Database`.
- Name the new database (e.g., `call_analysis`) and click `Save`.

## Step 2: Create Tables and Import Data

### 1. Open a New Query Tool
- Right-click on the database you created (or any existing database) and select `Query Tool`.
- This will open a new SQL query editor.

### 2. Create Tables
- Copy the SQL code for creating tables (from the `CREATE TABLE` statements) and paste it into the query editor.
- Click the **Run** button (lightning bolt icon) to execute the script and create the tables.

### 3. Set Date Style
- Execute the command:
  ```sql
  SET datestyle = 'ISO, MDY';
to configure the date format for your session.

## Step 2: Create Tables and Import Data (Continued)

### 4. Import Data from CSV Files
- Ensure that your CSV files (`calls.csv`, `reason.csv`, `customers.csv`, `sentiment_statistics.csv`, `test.csv`) are available in the specified directory (`C:\UA\`).
- Update the paths in the `COPY` statements if necessary.
- Copy the `COPY` statements into the query editor and run them to import data into the corresponding tables.

> **Note:** Ensure that the CSV files are properly formatted and match the schema of the tables (column names and types).

## Step 3: Perform Analysis and Retrieve Insights

### 1. Calculate Average Handle Time (AHT) and Average Speed to Answer (AST)
- Copy the SQL code under `-- Calculate Average Handle Time (AHT) and Average Speed to Answer (AST)` and paste it into the query editor.
- Run the query to calculate and display AHT and AST based on normalized call reasons.

### 2. Calculate AHT with Sentiment Analysis
- Use the second query block under `-- Calculate Average Handle Time (AHT) and Add Key Factors`.
- Run the query to gain insights into average handle times and sentiment scores.

### 3. Identify High Volume Call Periods
- Execute the query under `-- Determine High Volume Call Periods` to identify high-volume call periods by day and hour.

### 4. Correlate AHT and AST with Call Volume
- Run the `-- Correlate AHT and AST with Call Volume` query to identify correlations between handle time, speed to answer, and call volumes.

### 5. Identify Key Drivers of Long AHT and AST
- Use the query under `-- Identify Key Drivers of Long AHT and AST` to determine key drivers that impact AHT and AST during high call volume periods.

### 6. Calculate Percentage Differences
- Run the queries under `-- Percentage Difference` to calculate the absolute percentage difference between the most and least frequent call reasons.

### 7. Analyze Top Recurring Call Reasons with Transcripts
- Execute the last query block to identify top recurring reasons along with their transcripts for further analysis.
# Running Call Transcript Analysis in Jupyter Notebook

Follow these steps to run the Call Transcript Analysis project in Jupyter Notebook:

## Prerequisites

1. **Install Jupyter Notebook**:
   If you don't have Jupyter installed, you can install it using pip:

   ```bash
   pip install jupyter
2. Install Required Libraries: Ensure you have the necessary libraries installed. You can install them using pip:
   pip install pandas matplotlib scikit-learn nltk

##Dataset Preparation
Download the Datasets:

Download the call transcripts dataset and save it as calls.csv.
Download the call reasons dataset and save it as reason.csv.
Place the Datasets:

Ensure that both files are placed in the correct directory:
C:/UA/calls.csv
C:/UA/reason.csv
Launch Jupyter Notebook
Open a terminal or command prompt.

Navigate to the directory where you want to create your notebook.

Start Jupyter Notebook

##Create a New Notebook
In the Jupyter Notebook interface, click on New and select Python 3 to create a new notebook.
Rename the notebook to something meaningful, like Call_Transcript_Analysis.ipynb.
##Copy the Code into the Notebook
Copy the code provided in your project (excluding the Python code section) and paste it into the first cell of your notebook.
Execute the cell by pressing Shift + Enter.
##Running the Code
Ensure you run the necessary imports and code blocks in separate cells.
Execute each cell sequentially to ensure proper execution.
