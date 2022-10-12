from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("PySparkTest").getOrCreate() 

data = [1, 2, 3, 4, 5]
distData = spark.sparkContext.parallelize(data)
f = distData.filter(lambda x: x % 2 == 0)
f.take(5)
f = distData.map(lambda x: x % 2 == 0)
f.take(5)
