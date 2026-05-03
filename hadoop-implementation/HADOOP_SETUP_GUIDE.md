# Hadoop Implementation Guide

## 🎯 Overview

This guide documents the complete process of migrating the ABC Electronics Data Warehouse from SQL Server to Hadoop HDFS, setting up Apache Hive for SQL-like querying, and implementing Apache Pig for ETL transformations.

---

## 📋 Prerequisites

### Software Requirements
- **Hadoop 3.3.x** or later
- **Apache Hive 3.1.2** or later
- **Apache Pig 0.16.0** or later
- **Java JDK 8** or later
- **Ubuntu 20.04+** (or similar Linux distribution)

### Hardware Requirements
- **Minimum:** 8GB RAM, 50GB storage
- **Recommended:** 16GB RAM, 100GB storage
- **For cluster:** 3+ nodes with 16GB RAM each

---

## 🚀 Step 1: Hadoop Setup

### 1.1 Install Java

```bash
# Update package list
sudo apt-get update

# Install OpenJDK 8
sudo apt-get install openjdk-8-jdk -y

# Verify installation
java -version

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# Add to .bashrc for persistence
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
```

### 1.2 Download and Install Hadoop

```bash
# Download Hadoop 3.3.6
cd ~
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz

# Extract
tar -xzf hadoop-3.3.6.tar.gz

# Move to /usr/local
sudo mv hadoop-3.3.6 /usr/local/hadoop

# Set Hadoop environment variables
export HADOOP_HOME=/usr/local/hadoop
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Add to .bashrc
echo 'export HADOOP_HOME=/usr/local/hadoop' >> ~/.bashrc
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc
```

### 1.3 Configure Hadoop

**Edit `core-site.xml`:**
```bash
nano $HADOOP_HOME/etc/hadoop/core-site.xml
```

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/hadoop/tmpdata</value>
    </property>
</configuration>
```

**Edit `hdfs-site.xml`:**
```bash
nano $HADOOP_HOME/etc/hadoop/hdfs-site.xml
```

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/hadoop/dfsdata/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/hadoop/dfsdata/datanode</value>
    </property>
</configuration>
```

**Create directories:**
```bash
mkdir -p /home/hadoop/tmpdata
mkdir -p /home/hadoop/dfsdata/namenode
mkdir -p /home/hadoop/dfsdata/datanode
```

### 1.4 Format HDFS and Start Services

```bash
# Format namenode (ONLY FIRST TIME)
hdfs namenode -format

# Start HDFS
start-dfs.sh

# Verify services are running
jps

# You should see:
# - NameNode
# - DataNode
# - SecondaryNameNode
```

### 1.5 Verify HDFS

```bash
# Check HDFS status
hdfs dfsadmin -report

# Create test directory
hdfs dfs -mkdir -p /user/hadoop

# List HDFS contents
hdfs dfs -ls /

# Access Web UI
# Open browser: http://localhost:9870
```

---

## 📊 Step 2: Data Export from SQL Server

### 2.1 Export Tables to CSV

**PowerShell script (Windows):**
```powershell
# Export Dim_Date
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Dim_Date" -o "Dim_Date.csv" -s "," -W

# Export Dim_Product
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Dim_Product" -o "Dim_Product.csv" -s "," -W

# Export Dim_Supplier
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Dim_Supplier" -o "Dim_Supplier.csv" -s "," -W

# Export Dim_Location
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Dim_Location" -o "Dim_Location.csv" -s "," -W

# Export Fact_PurchaseOrder_Sent
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Fact_PurchaseOrder_Sent" -o "Fact_PO_Sent.csv" -s "," -W

# Export Fact_PurchaseOrder_Received
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Fact_PurchaseOrder_Received" -o "Fact_PO_Received.csv" -s "," -W

# Export Fact_Stock_Levels
sqlcmd -S localhost -d ABC_Electronics_DW -Q "SELECT * FROM Fact_Stock_Levels" -o "Fact_Stock_Levels.csv" -s "," -W
```

### 2.2 Clean CSV Files

```bash
# Remove SQL Server headers and formatting
sed -i '1,2d' *.csv  # Remove first 2 lines (header row)

# Replace NULL with empty string
sed -i 's/NULL//g' *.csv

# Verify files
head -5 Dim_Date.csv
wc -l *.csv  # Count lines
```

---

## 🐘 Step 3: Load Data into HDFS

### 3.1 Create HDFS Directory Structure

```bash
# Create warehouse directory
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw

# Create dimension directories
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/dim_date
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/dim_product
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/dim_supplier
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/dim_location

# Create fact directories
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/fact_po_sent
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/fact_po_received
hdfs dfs -mkdir -p /user/hive/warehouse/abc_dw/fact_stock_levels

# Verify structure
hdfs dfs -ls -R /user/hive/warehouse/abc_dw
```

### 3.2 Upload CSV Files to HDFS

```bash
# Upload dimension tables
hdfs dfs -put Dim_Date.csv /user/hive/warehouse/abc_dw/dim_date/
hdfs dfs -put Dim_Product.csv /user/hive/warehouse/abc_dw/dim_product/
hdfs dfs -put Dim_Supplier.csv /user/hive/warehouse/abc_dw/dim_supplier/
hdfs dfs -put Dim_Location.csv /user/hive/warehouse/abc_dw/dim_location/

# Upload fact tables
hdfs dfs -put Fact_PO_Sent.csv /user/hive/warehouse/abc_dw/fact_po_sent/
hdfs dfs -put Fact_PO_Received.csv /user/hive/warehouse/abc_dw/fact_po_received/
hdfs dfs -put Fact_Stock_Levels.csv /user/hive/warehouse/abc_dw/fact_stock_levels/

# Verify uploads
hdfs dfs -ls /user/hive/warehouse/abc_dw/dim_date
hdfs dfs -cat /user/hive/warehouse/abc_dw/dim_date/Dim_Date.csv | head -5
```

---

## 🔍 Step 4: Apache Hive Setup

### 4.1 Install Hive

```bash
# Download Hive 3.1.2
cd ~
wget https://downloads.apache.org/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz

# Extract
tar -xzf apache-hive-3.1.2-bin.tar.gz

# Move to /usr/local
sudo mv apache-hive-3.1.2-bin /usr/local/hive

# Set environment variables
export HIVE_HOME=/usr/local/hive
export PATH=$PATH:$HIVE_HOME/bin

# Add to .bashrc
echo 'export HIVE_HOME=/usr/local/hive' >> ~/.bashrc
echo 'export PATH=$PATH:$HIVE_HOME/bin' >> ~/.bashrc
```

### 4.2 Configure Hive

**Create `hive-site.xml`:**
```bash
cd $HIVE_HOME/conf
cp hive-default.xml.template hive-site.xml
nano hive-site.xml
```

Add these properties:
```xml
<property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:derby:;databaseName=/home/hadoop/metastore_db;create=true</value>
</property>

<property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
</property>

<property>
    <name>hive.server2.thrift.port</name>
    <value>10000</value>
</property>
```

### 4.3 Initialize Hive Metastore

```bash
# Initialize Derby database
schematool -initSchema -dbType derby

# Start Hive
hive

# You should see: hive>
```

---

## 📋 Step 5: Create Hive Tables

### 5.1 Create Dimension Tables in Hive

```sql
-- Start Hive
hive

-- Create database
CREATE DATABASE IF NOT EXISTS abc_electronics_dw;
USE abc_electronics_dw;

-- Dim_Date
CREATE EXTERNAL TABLE dim_date (
    DateKey INT,
    FullDate STRING,
    DayOfWeek STRING,
    DayOfMonth INT,
    DayOfYear INT,
    WeekOfYear INT,
    Month INT,
    MonthName STRING,
    Quarter INT,
    Year INT,
    IsWeekend BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/dim_date';

-- Dim_Product
CREATE EXTERNAL TABLE dim_product (
    ProductKey INT,
    ProductID STRING,
    ProductName STRING,
    ProductType STRING,
    Brand STRING,
    Category STRING,
    UnitPrice DECIMAL(10,2),
    ReorderLevel INT,
    CurrentStockLevel INT,
    EffectiveDate STRING,
    ExpiryDate STRING,
    IsCurrent BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/dim_product';

-- Dim_Supplier
CREATE EXTERNAL TABLE dim_supplier (
    SupplierKey INT,
    SupplierID STRING,
    SupplierName STRING,
    ContactPerson STRING,
    PhoneNumber STRING,
    Email STRING,
    Address STRING,
    City STRING,
    Country STRING,
    EffectiveDate STRING,
    ExpiryDate STRING,
    IsCurrent BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/dim_supplier';

-- Dim_Location
CREATE EXTERNAL TABLE dim_location (
    LocationKey INT,
    LocationID STRING,
    LocationName STRING,
    LocationType STRING,
    Capacity INT,
    WarehouseSection STRING,
    City STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/dim_location';
```

### 5.2 Create Fact Tables in Hive

```sql
-- Fact_PurchaseOrder_Sent
CREATE EXTERNAL TABLE fact_po_sent (
    PO_SentKey INT,
    DateKey INT,
    ProductKey INT,
    SupplierKey INT,
    PurchaseOrderID STRING,
    OrderedQuantity INT,
    UnitPrice DECIMAL(10,2),
    OrderValue DECIMAL(12,2),
    ExpectedDeliveryDays INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/fact_po_sent';

-- Fact_PurchaseOrder_Received
CREATE EXTERNAL TABLE fact_po_received (
    PO_ReceivedKey INT,
    DateKey INT,
    ProductKey INT,
    SupplierKey INT,
    LocationKey INT,
    PurchaseOrderID STRING,
    OrderedQuantity INT,
    ReceivedQuantity INT,
    DamagedQuantity INT,
    UnitPrice DECIMAL(10,2),
    TotalValue DECIMAL(12,2),
    DeliveryDelay INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/fact_po_received';

-- Fact_Stock_Levels
CREATE EXTERNAL TABLE fact_stock_levels (
    StockLevelKey INT,
    DateKey INT,
    ProductKey INT,
    LocationKey INT,
    OpeningStock INT,
    StockReceived INT,
    StockSold INT,
    StockAdjustment INT,
    ClosingStock INT,
    MinimumStockLevel INT,
    StockValue DECIMAL(12,2),
    IsUnderstock BOOLEAN,
    IsOverstock BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/abc_dw/fact_stock_levels';
```

### 5.3 Verify Tables

```sql
-- Show all tables
SHOW TABLES;

-- Verify data loaded
SELECT * FROM dim_date LIMIT 10;
SELECT * FROM dim_product LIMIT 10;
SELECT COUNT(*) FROM fact_stock_levels;
```

---

## 🐷 Step 6: Apache Pig Implementation

### 6.1 Install Apache Pig

```bash
# Download Pig 0.17.0
cd ~
wget https://downloads.apache.org/pig/pig-0.17.0/pig-0.17.0.tar.gz

# Extract
tar -xzf pig-0.17.0.tar.gz

# Move to /usr/local
sudo mv pig-0.17.0 /usr/local/pig

# Set environment variables
export PIG_HOME=/usr/local/pig
export PATH=$PATH:$PIG_HOME/bin

# Add to .bashrc
echo 'export PIG_HOME=/usr/local/pig' >> ~/.bashrc
echo 'export PATH=$PATH:$PIG_HOME/bin' >> ~/.bashrc

# Verify installation
pig -version
```

### 6.2 Start Pig Grunt Shell

```bash
# Start Pig in local mode
pig -x local

# Start Pig in MapReduce mode
pig -x mapreduce

# You should see: grunt>
```

### 6.3 Sample Pig Scripts

See `pig-scripts/` folder for complete implementations.

---

## ✅ Verification & Testing

### Test 1: HDFS Data Integrity

```bash
# Check file count
hdfs dfs -count /user/hive/warehouse/abc_dw

# Verify file sizes
hdfs dfs -du -h /user/hive/warehouse/abc_dw

# Sample data
hdfs dfs -cat /user/hive/warehouse/abc_dw/fact_stock_levels/Fact_Stock_Levels.csv | head -10
```

### Test 2: Hive Queries

```sql
-- Join query test
SELECT 
    d.FullDate,
    p.ProductName,
    f.ClosingStock
FROM fact_stock_levels f
JOIN dim_date d ON f.DateKey = d.DateKey
JOIN dim_product p ON f.ProductKey = p.ProductKey
LIMIT 10;

-- Aggregation test
SELECT 
    s.SupplierName,
    COUNT(*) as OrderCount,
    SUM(OrderValue) as TotalValue
FROM fact_po_sent f
JOIN dim_supplier s ON f.SupplierKey = s.SupplierKey
GROUP BY s.SupplierName;
```

---

## 🎯 Performance Optimization

### Enable Compression

```sql
SET hive.exec.compress.output=true;
SET mapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec;
```

### Partitioning Strategy

```sql
-- Partition fact table by year
CREATE TABLE fact_stock_levels_partitioned (
    StockLevelKey INT,
    DateKey INT,
    ProductKey INT,
    -- ... other fields
)
PARTITIONED BY (year INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

-- Load data into partitions
INSERT INTO TABLE fact_stock_levels_partitioned PARTITION(year=2024)
SELECT * FROM fact_stock_levels WHERE year = 2024;
```

---

## 📊 Monitoring & Maintenance

### Check Hadoop Services

```bash
# Check running services
jps

# Check HDFS health
hdfs fsck / -files -blocks -locations

# Check disk usage
hdfs dfs -df -h
```

### Hive Metastore Maintenance

```bash
# Backup metastore
cp -r /home/hadoop/metastore_db /backup/metastore_$(date +%Y%m%d)

# Clear query logs
rm -rf /tmp/hive/*.log
```

---

## 🆘 Troubleshooting

### Issue: NameNode not starting

```bash
# Check logs
cat $HADOOP_HOME/logs/hadoop-*-namenode-*.log

# Reformat (WARNING: deletes all data)
stop-all.sh
rm -rf /home/hadoop/dfsdata/*
hdfs namenode -format
start-dfs.sh
```

### Issue: Hive connection error

```bash
# Reset metastore
rm -rf /home/hadoop/metastore_db
schematool -initSchema -dbType derby
```

### Issue: Pig script fails

```bash
# Run in debug mode
pig -x local -debug DEBUG myscript.pig

# Check Hadoop logs
cat $HADOOP_HOME/logs/userlogs/application_*/container_*/stderr
```

---

## 📚 Additional Resources

- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/current/)
- [Apache Hive Documentation](https://hive.apache.org/)
- [Apache Pig Documentation](https://pig.apache.org/docs/latest/)

---

**Implementation Date:** January - May 2026  
**Environment:** Ubuntu 20.04, Hadoop 3.3.6, Hive 3.1.2, Pig 0.17.0
