# install.packages('installr')
# library(installr)
# installr()
# install.RStudio()

if(!"remotes" %in% installed.packages()) install.packages("remotes")
if(!"HonestDiD" %in% installed.packages()) remotes::install_github("asheshrambachan/HonestDiD")
library("HonestDiD")

if(!"devtools" %in% installed.packages()) install.packages("devtools")
if(!"lpdid" %in% installed.packages()) devtools::install_github("alexCardazzi/lpdid")
library("lpdid")

if (!require("fwildclusterboot")) install.packages('fwildclusterboot', repos ='https://s3alfisc.r-universe.dev')
if (!require("leebounds")) remotes::install_github("haluong89-bcn/leebounds")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  here,
  data.table,
  readxl,
  MASS,
  tidyverse, # data cleaning and visualization
  ggplot2,
  pals,
  janitor,
  easystats, # easystats::install_suggested()
  countrycode,
  questionr,
  gtsummary,
  gt,
  panelView, # Visualize treatment assignment status
  fect, # get.cohort() function
  fixest, # high-dimensional fixed effects
  eventstudyr, # event-study analysis Freyaldenhoven et al
  did,
  didimputation,
  DIDmultiplegtDYN,
  fwildclusterboot,
  margins,
  ggeffects, # plot predicted values (aka margins)
  lmtest, # calculate robust standard errors
  sandwich,
  experiment,
  causalweight
)
