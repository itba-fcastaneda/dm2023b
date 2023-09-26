# limpio la memoria
rm(list = ls()) # remove all objects
gc() # garbage collection

require("data.table")
require("rpart")
require("rpart.plot")

setwd("~/devel/itba-fcastaneda/dm2023b/buckets/b1/")

# cargo el dataset
dataset <- fread("./datasets/dataset_pequeno.csv")

semilla = 800161
cant_canarios = 1

dir.create("./exp/", showWarnings = FALSE)
dir.create(paste("./exp/EA4810-",semilla,sep=""), showWarnings = FALSE)
setwd(paste("./exp/EA4810-",semilla,sep=""))

# uso esta semilla para los canaritos
set.seed(semilla)

# agrego 30 variables canarito,
#  random distribucion uniforme en el intervalo [0,1]

for (i in 1:cant_canarios) dataset[, paste0("canarito", i) := runif(nrow(dataset))]


# Primero  veo como quedan mis arboles
modelo <- rpart(
    formula = "clase_ternaria ~ .",
    data = dataset[foto_mes == 202107, ],
    model = TRUE,
    xval = 0,
    cp = -1,
    minsplit = 100,
    minbucket = 100,
    maxdepth = 10
)


# Grabo el arbol de canaritos
pdf(file = paste("./",cant_canarios,"_arbol_canaritos.pdf", sep=""), width = 28, height = 4)
prp(modelo,
    extra = 101, digits = -5,
    branch = 1, type = 4, varlen = 0, faclen = 0
)

dev.off()
