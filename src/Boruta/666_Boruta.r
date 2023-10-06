library(Boruta)
require("data.table")
require("randomForest")

setwd( "~/buckets/b1/")
boruta_semilla = 800161

# dataset_input <- paste0("./exp/", PARAM$exp_input, "/dataset.csv.gz")
dataset_input <- paste0("./datasets/dataset_pequeno.csv")

dataset <- fread(dataset_input)
colnames(dataset)[which(!(sapply(dataset, typeof) %in% c("integer", "double")))]

#setorder(dataset, numero_de_cliente, foto_mes)

dataset[, clase01 := ifelse(clase_ternaria == "CONTINUA", 0, 1)]
set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")

campos_buenos <- setdiff(
  colnames(dataset),
  c("clase_ternaria", "foto_mes")
)

set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
azar <- runif(nrow(dataset))

dataset_rf <- copy(dataset[, campos_buenos, with = FALSE])
set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
azar <- runif(nrow(dataset_rf))

dataset_rf[, entrenamiento :=
             as.integer(clase01 == 1 | azar < 0.10)]

set.seed(boruta_semilla, kind = "L'Ecuyer-CMRG")
dtrain <- na.roughfix(dataset_rf)

ncol_antes <- ncol(dataset)

boruta.train <- Boruta(
  clase01~. ,
  data = dtrain,
)


