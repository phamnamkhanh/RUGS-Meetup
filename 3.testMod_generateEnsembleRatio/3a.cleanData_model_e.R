#I will setwd("/MY_Working_Directory/data") where the kaggle train/test data are placed
source("../baseFunctions_cleanData.R")

trainData<-read.csv("train_wHex.csv")

#use apr 2014 data as ensemble test data
trainData$month<-month(trainData$created_time)
trainData$year<-year(trainData$created_time)
idNo<-trainData[trainData$year==2013&trainData$month==4,"id"]

testData<-trainData[trainData$id %in% idNo,]
trainData<-trainData[!trainData$id %in% idNo,]
#save the answers
testDataAns<-testData[,c("id","num_votes","num_comments","num_views")]
#remove votes,comments,views cols from test data
testData<-subset(testData, select=-c(num_votes,num_comments,num_views))

trainData2<-trainData[,!(names(trainData) %in% c("latitude","longitude"))]

#replace string NA with unknown
trainData2$tag_type<-as.character(trainData2$tag_type)
trainData2$tag_type[is.na(trainData2$tag_type)]<-"unknown"
trainData2$tag_type<-as.factor(trainData2$tag_type)

testData$tag_type<-as.character(testData$tag_type)
testData$tag_type[is.na(testData$tag_type)]<-"unknown"
testData$tag_type<-as.factor(testData$tag_type)

trainData2$source<-as.character(trainData2$source)
trainData2$source[is.na(trainData2$source)]<-"unknown"
trainData2$source<-as.factor(trainData2$source)

testData$source<-as.character(testData$source)
testData$source[is.na(testData$source)]<-"unknown"
testData$source<-as.factor(testData$source)

#get data table of median values by city, tag type
trainData2$num_views<-as.numeric(trainData2$num_views)
trainData2$num_votes<-as.numeric(trainData2$num_votes)
trainData2$num_comments<-as.numeric(trainData2$num_comments)

#remove first 10 month 2012 data as they have higher d from 2013 Apr
#remove march 2013 as it has high d as well.
#d is like the distance of difference, smaller d = the two data sets are closer
# ksTest<-ks.test(trainData2$num_views[trainData2$month==4&trainData2$year==2013],
#                 trainData2$num_views[trainData2$month==9&trainData2$year==2012])
trainData2<-trainData2[trainData2$month==11|trainData2$month==12|trainData2$year==2013,]
trainData2<-trainData2[trainData2$month!=3,]

#no longer need the date cols
#test data drop year and month later down the code
trainData2$created_time<-NULL
# trainData2$year<-NULL
# trainData2$month<-NULL

#combine the remote_API tags with tag_type
trainData2<-remapAPI(trainData2)
testData2<-testData[,!(names(testData) %in% c("latitude","longitude","created_time"))]
testData2<-remapAPI(testData2)

# #chicargo remote_api_created is one of the kind weird and should be modelled seperately
# ksTest_city<- ks.test(trainData2$num_views[trainData2$city=="oakland"],
#                       trainData2$num_views[trainData2$city=="chicargo"&trainData2$source!="remote_api_created"])
# 
# ksTest_city2<-ks.test(trainData2$num_views[trainData2$city=="chicargo"],
#                       trainData2$num_views[trainData2$city=="chicargo"&trainData2$source!="remote_api_created"])
# 
# #richmond, new_haven have d=0 which is strange
# ksTest_city3<-ks.test(trainData2$num_views[trainData2$city=="new_haven"],
#                       trainData2$num_views[trainData2$city=="new_haven"&trainData2$source!="remote_api_created"])

trainDataMod<-trainData2
trainDataMod<-trainDataMod[!(trainDataMod$city=="chicargo"&trainDataMod$source=="remote_api_created"),]
testDataMod<-testData2[!(testData2$city=="chicargo"&testData2$source=="remote_api_created"),]
trainDataMod<-data.table(trainDataMod)

#remove summary/desc
trainData2<-trainData2[,!(names(trainData2) %in% c("summary","description"))]
testData2<-testData2[,!(names(testData2) %in% c("summary","description"))]

#remove train data more than 3 Median Absolute Deviation away from median (outliers)
trainDataMod<-madRemove(trainDataMod,3)

#convert traindataRf back to data frame
trainDataMod<-data.frame(trainDataMod)

#log view (it has large variation)
trainDataMod$num_views<-log(trainDataMod$num_views+1)

#relevel test data to match train data tags, source. All NAs will be estimated using median in modeling
testDataMod$tag_type<-factor(testDataMod$tag_type,levels=levels(trainDataMod$tag_type))
testDataMod$source<-factor(testDataMod$source,levels=levels(trainDataMod$source))
testDataMod<-testDataMod[!is.na(testDataMod$tag_type),]
testDataMod<-testDataMod[!is.na(testDataMod$source),]

#reclassify text + split tags
trainDataMod<-wordMine(trainDataMod,"all")
testCol<-names(trainDataMod)
drops <- c("num_votes","num_comments","num_views","year","month")
testCol<-testCol[!testCol %in% drops]
testDataMod<-wordMine(testDataMod,testCol)
trainDataMod<-trainDataMod[,!(names(trainDataMod) %in% c("summary","description"))]
testDataMod<-testDataMod[,!(names(testDataMod) %in% c("summary","description"))]

#save the data
save(testData2, file = "testDataEnsemble.Rdata")
save(testDataMod, file = "testDataModEnsemble.Rdata")
save(testDataAns, file = "testDataEnsembleAns.Rdata")
save(trainData2, file = "trainDataEnsemble.Rdata")
save(trainDataMod, file = "trainDataModEnsemble.Rdata")