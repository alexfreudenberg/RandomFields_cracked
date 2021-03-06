\name{RFfitoptimiser}
\alias{RFfitoptimiser}
\alias{RFfitOptimiser}
\title{Optimisers for
  fitting model parameters to spatial data
}
\description{
  See \command{\link{RFfit}} for a detailed description of
  the fitting procedure.
}

\details{
  Two parameters, see also \command{\link{RFoptions}}
  can be passed to \command{\link{RFfit}} that allow
  for choosing an optimiser different from \command{\link[stats]{optim}}:

  \code{optimiser} takes one of the values
  \code{"optim"}, \code{"optimx"}, \code{"soma"}, \code{"nloptr"},
  \code{"GenSA"}, \code{"minqa"}, \code{"pso"} or \code{"DEoptim"},
  see the corresponding packages for a description.

  If \code{optimiser="nloptr"}, then the additional parameter
  \code{algorithm} must be given which takes the values
  \code{"NLOPT_GN_DIRECT"},  
  \code{"NLOPT_GN_DIRECT_L"},
  \code{"NLOPT_GN_DIRECT_L_RAND"}, 
  \code{"NLOPT_GN_DIRECT_NOSCAL"},
  \code{"NLOPT_GN_DIRECT_L_NOSCAL"}, 
  \code{"NLOPT_GN_DIRECT_L_RAND_NOSCAL"},
  \code{"NLOPT_GN_ORIG_DIRECT"}, 
  \code{"NLOPT_GN_ORIG_DIRECT_L"},
  \code{"NLOPT_LN_PRAXIS"}, 
  \code{"NLOPT_GN_CRS2_LM"}, 
  \code{"NLOPT_LN_COBYLA"},
  \code{"NLOPT_LN_NELDERMEAD"}, 
  \code{"NLOPT_LN_SBPLX"},
  \code{"NLOPT_LN_BOBYQA"},
  \code{"NLOPT_GN_ISRES"},
  see \pkg{nloptr} for a description.
    
}

\me

\seealso{
  \command{\link{RFfit}}, \command{\link{RFoptions}}
}
\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

\dontrun{
## Here some alternative optimisers to 'optim' are considered.
## All but the \pkg{nloptr} algorithms are largely slower than 'optim'.
## Only a few of them return results as good as 'optim'.

data(soil)
str(soil)
soil <- RFspatialPointsDataFrame(
 coords = soil[ , c("x.coord", "y.coord")],
 data = soil[ , c("moisture", "NO3.N", "Total.N", "NH4.N", "DOC", "N20N")],
 RFparams=list(vdim=6, n=1)
)
dta <- soil["moisture"]
\dontshow{if (RFoptions()$internal$examples_red) {
  warning("data have been reduced !")
  All <- 1:7 
  rm(soil)
  data(soil)
  soil <- RFspatialPointsDataFrame(
     coords = soil[All, c("x.coord", "y.coord")],
     data = soil[All, c("moisture", "NO3.N", "Total.N",
      "NH4.N", "DOC", "N20N")],
      RFparams=list(vdim=6, n=1)
  )
  dta <- soil["moisture"]
}}

model <- ~1 + RMwhittle(scale=NA, var=NA, nu=NA) + RMnugget(var=NA)
\dontshow{if (RFoptions()$internal$examples_red){model<-~1+RMwhittle(scale=NA,var=NA,nu=1/2)}}
## standard optimiser 'optim'
print(system.time(fit <- RFfit(model, data=dta)))
print(fit)

opt <- "optimx" #  30 sec; better result
print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt))))
print(fit2)

\dontshow{\dontrun{ %in 6 sep 2017, soma has leak problems
opt <- "soma" #  450 sec % sehr schlecht
print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt))))
print(fit2)
}}

opt <- "minqa" # 330 sec %ok
print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt))))
print(fit2)


opt <- "nloptr"
algorithm <- RC_NLOPTR_NAMES
\dontshow{if(!interactive()) algorithm <- RC_NLOPTR_NAMES[1]}
for (i in 1:length(algorithm)) { % all algorithms are fast
  print(algorithm[i])
  print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt,
                                    algorithm=algorithm[i]))))
  print(fit2)
}



if (interactive()) {
## the following two optimisers are too slow to be run on CRAN.

opt <- "pso" # 600 sec
print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt))))
print(fit2)

opt <- "GenSA" #  10^4 sec
print(system.time(fit2 <- try(RFfit(model, data=dta, optimiser=opt))))
print(fit2)
}
}

\dontshow{RFoptions(modus_operandi="normal")}
\dontshow{FinalizeExample()}}

\keyword{spatial}
\keyword{optimize}

