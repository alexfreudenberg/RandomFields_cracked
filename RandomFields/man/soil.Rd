\name{soil}
\docType{data}
\alias{soil}
\title{Soil data of North Bavaria, Germany}
\usage{data(soil)}
\description{
 Soil physical and chemical data collected on a field in the
 Weissenstaedter Becken, Germany
}
\format{
 This data frame contains the following columns:
 \describe{
 \item{x.coord}{x coordinates given in cm}
 \item{y.coord}{y coordinates given in cm}
 \item{nr}{number of the samples, which were taken in this order}
 \item{moisture}{moisture content [Kg/Kg * 100\%]}
 \item{NO3.N}{nitrate nitrogen [mg/Kg]}
 \item{Total.N}{total nitrogen [mg/Kg]}
 \item{NH4.N}{ammonium nitrogen [mg/Kg]}
 \item{DOC}{dissolved organic carbon [mg/Kg]}
 \item{N20N}{nitrous oxide [mg/Kg dried substance]}
 }
}
\details{
 For technical reasons some of the data were obtained as differences
 of two measurements (which are not available anymore). Therefore,
 some of the data have negative values.
}
\source{
 The data were collected by Wolfgang Falk,
 Soil Physics Group,
% \url{http://www.geo.uni-bayreuth.de/bodenphysik/Welcome.html},
 University of Bayreuth, Germany.
}
\references{
 Falk, W. (2000)
 \emph{Kleinskalige raeumliche Variabilitaet von Lachgas und bodenchemischen
 Parameters [Small Scale Spatial Variability of Nitrous Oxide and
 Pedo-Chemical Parameters]},
 Master thesis, University of Bayreuth, Germany.
}
\me
\examples{\dontshow{StartExample()} % library("RandomFields")
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

################################################################
## ##
## a geostatistical analysis that demonstrates ##
## features of the package 'RandomFields' ##
## ##
################################################################


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
  rm(soil) ## muss vorher entfernt werden, sonst funktioniert data(soil)
  ##          nicht sicher
  data(soil)
  All <- 1:7
  soil <- RFspatialPointsDataFrame(
     coords = soil[All, c("x.coord", "y.coord")],
     data = soil[All, c("moisture", "NO3.N", "Total.N",
      "NH4.N", "DOC", "N20N")],
      RFparams=list(vdim=6, n=1)
  )
  dta <- soil["moisture"]
}}

## plot the data first
colour <- rainbow(100)
plot(dta, col=colour)


## fit by eye
gui.model <- RFgui(dta) 
\dontshow{if (!interactive()) gui.model <- RMexp()} %ok

## fit by ML
model <- ~1 + RMwhittle(scale=NA, var=NA, nu=NA) + RMnugget(var=NA)
(fit <- RFfit(model, data=dta))
plot(fit, method=c("ml", "plain", "sqrt.nr", "sd.inv"),
     model = gui.model, col=1:8)

## Kriging ...
x <- seq(min(dta@coords[, 1]), max(dta@coords[, 1]), l=121)
k <- RFinterpolate(fit, x=x, y=x, data=dta)
plot(x=k, col=colour)
plot(x=k, y=dta, col=colour)

## what is the probability that at no point of the
## grid given by x and y the moisture is greater than 24 percent?
% works well since fit$ml:nugget==0!!!!
cs <- RFsimulate(model=fit@ml, x=x, y=x, data=dta, n=50)
plot(cs, col=colour)
plot(cs, y=dta, col=colour)
Print(mean(apply(as.array(cs) <= 24, 3, all))) ## about 40 percent ...

\dontshow{FinalizeExample()}}

\keyword{datasets}




