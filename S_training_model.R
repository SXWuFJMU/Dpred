library(BSgenome)
library(dplyr)
library(e1071)
library(dplyr)
library(caret)
library(ROCR)
Pdata <- readDNAStringSet(paste0("/FA/Spombe_D_P.fa"))
Ndata <- readDNAStringSet(paste0("/FA/Spombe_D_N.fa"))

XXX1 <- c(138)
set.seed(XXX1)
Ndata_s <- Ndata[sample(1:length(Ndata))][1:(length(Pdata))]
set.seed(123)
Pdata <- Pdata[sample(1:length(Pdata))]

Ndata_s1 <- gsub("T","U",as.data.frame(Ndata_s)$x)
Pdata1 <- gsub("T","U",as.data.frame(Pdata)$x)

S_order_COMPOSI <- readRDS("/F1_order/S_order_COMPOSI.rds")
S_order_ChemicalProper <- readRDS("/F1_order/S_order_ChemicalProper.rds")
S_order_PseKNC <- readRDS("/F1_order/S_order_PseKNC.rds")

##feature encoding
source("/methods/composition.R")
source("/methods/PseKNC.R")
source("/methods/ChemicialProperty.R")
Ndata_F1 <- list()
Pdata_F1 <- list()
Pdata_F1[[1]] <- composition(Pdata1)[,S_order_COMPOSI]
Pdata_F1[[2]] <- ChemicalProperty(as.data.frame(Pdata)$x)[,S_order_ChemicalProper]
Pdata_F1[[3]] <- PseKNC(as.data.frame(Pdata)$x)[,S_order_PseKNC]
Ndata_F1[[1]] <- composition(Ndata_s1)[,S_order_COMPOSI]
Ndata_F1[[2]] <- ChemicalProperty(as.data.frame(Ndata_s)$x)[,S_order_ChemicalProper]
Ndata_F1[[3]] <- PseKNC(as.data.frame(Ndata_s)$x)[,S_order_PseKNC]


Pdata_F <- cbind(Pdata_F1[[1]],Pdata_F1[[2]],Pdata_F1[[3]])
Ndata_F <- cbind(Ndata_F1[[1]],Ndata_F1[[2]],Ndata_F1[[3]])

Train_nunber <- c(1:length(Pdata))[c(1:round(length(Pdata)/10*8))]
test_nunber <- c(1:length(Pdata))[-c(1:round(length(Pdata)/10*8))]


label_train <- c(rep("motif",length(Train_nunber)),rep("non",length(Train_nunber)))
label_train <- factor(label_train,labels=c("motif","non"))
testlabel <- c(rep(1,length(test_nunber)),rep(0,length(test_nunber)))

BIOmotifvsnontrain <- rbind(Pdata_F[Train_nunber,],Ndata_F[Train_nunber,])
BIOmotifvsnontest <- rbind(Pdata_F[test_nunber,],Ndata_F[test_nunber,])

##training model
BIOmotifvsnon_SVM <- svm(BIOmotifvsnontrain,label_train,cross=5, probability = TRUE)

pred <- predict(BIOmotifvsnon_SVM,BIOmotifvsnontest, probability = TRUE)
motif <- attr(pred, 'probabilities')[,1]
testppred <- prediction(motif,testlabel)
testpppred_auc <- performance(testppred,"auc")

#performance
attr(testpppred_auc,"y.values")[[1]]

