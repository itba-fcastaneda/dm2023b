# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#source("~/dm2023b/src/workflow-semillerio-fede/z711_CA_reparar_dataset-last-00.r")
#source("~/dm2023b/src/workflow-semillerio-fede/z721_DR_corregir_drifting-last-00.r")
source("~/dm2023b/src/workflow-semillerio-fede/z731_FE_historia-last-05.r")
source("~/dm2023b/src/workflow-semillerio-fede/z741_TS_training_strategy-last-05.r")

# ultimos pasos, muy lentos
source("~/dm2023b/src/workflow-semillerio-fede/z751_HT_lightgbm-last-04.r")
source("~/dm2023b/src/workflow-semillerio-fede/z795_ZZ_final_semillerio-last-04.r")
#source("~/dm2023b/src/workflow-semillerio-fede/z796_HB_semillerios_hibridacion-last-04.r")

