\name{RFcrossvalidate}
\alias{RFcrossvalidate}
\alias{print.crossvalidate}
\alias{summary.crossvalidate}
\alias{print.summary.crossvalidate}
%\alias{mleRF}% obsolete
\alias{RFcrossvalidate.default}
\title{Fitting model parameters to spatial data (regionalised variables)
  and to linear (mixed) models}
\description{
  The function estimates arbitrary parameters of
  a random field specification with various methods.
  Currently, the models to be fitted can be
  \itemize{
    \item{\link[=RPgauss]{Gaussian random fields}}
    \item{\link[=RFformula]{linear models}}
  }
  The fitting of max-stable random fields and others
  has not been implemented yet.
}
\usage{
RFcrossvalidate(model, x, y=NULL, z=NULL, T=NULL, grid=NULL, data,
                params, lower=NULL, upper=NULL, method="ml",
                users.guess=NULL, distances=NULL, dim, optim.control=NULL,
                transform=NULL, full = FALSE, ...)
}
\arguments{
  \item{model,params}{\argModel }
 \item{x}{\argX}
 \item{y,z}{\argYz}
 \item{T}{\argT}
 \item{grid}{\argGrid}
 \item{data}{\argData}
 \item{lower}{\argLower}
 \item{upper}{\argUpper}
 \item{method}{
   Single method to be used for estimating, either
   one of the \code{methods} or one of the \code{sub.methods}
   see \command{\link{RFfit}}
 }
 \item{users.guess}{\argUsersguess}
 \item{distances,dim}{\argDistances}
 \item{optim.control}{\argOptimcontrol}
 \item{transform}{\argTransform}
  \item{full}{logical.
   If \code{TRUE} then cross-validation is also performed
   for intermediate models used in
   \code{RFfit} (if any).
 }
 \item{...}{\argDots}
}
 
\section{Methods}{
 \describe{
   \item{print}{prints the summary}
   \item{summary}{gives a summary}
 }
}

\note{
  An important option is \code{cross_refit} that determines
  whether the model is refitted for each location left out.
  Default is \code{FALSE}. See also \command{\link[=RFoptionsFit]{RFoptions}}.
}


\value{
  An object of the \code{\link{class}} \code{"RFcrossvalidate"} which is
  a list with the following components, cf. \command{xvalid} in the
  package \pkg{geoR} :
  \item{data}{the original data.  }
  \item{predicted}{the values predicted by cross-validation.  }
  \item{krige.var}{the cross-validation prediction variance.  }
  \item{error}{the differences \code{data - predicted value}.   }
  \item{std.error}{the errors divided by the square root of the
    prediction variances.  }
  \item{p}{
    In contrast to \pkg{geoR} the p-value is returned,
    i.e. the probability
    that a difference with absolute value larger than the absolute
    value of the actual difference is observed.


    A method for \code{summary} returns summary statistics for the errors
    and standard errors similar to \pkg{geoR}.
  
    If \code{cross_refit = TRUE} and \code{detailed_output = TRUE}
    the returned object also contains a \code{fitted} which is
    a list of fitted models.
  }
}

\references{
  \itemize{
    \item Ribeiro, P.J., Jr. and Diggle, P.J (2014) R package \pkg{geoR}.
    
    \item Burnham, K. P. and Anderson, D. R. (2002)
    \emph{Model selection and Multi-Model Inference: A Practical
      Information-Theoretic Approach.}
    2nd edition. New York: Springer.
 }
}

\me

\note{This function does not depend on the value of
 \command{\link{RFoptions}}\code{()$PracticalRange}. 
 The function \code{RFcrossvalidate} always uses the standard specification
 of the covariance model as given in \command{\link{RMmodel}}.
}
\seealso{
  \command{\link{RFratiotest}}
  \command{\link{RFfit}}
  \command{\link{RFoptionsFit}}
  \command{\link{RMmodel}},
  \code{\link[=RandomFields-package]{RandomFields}},
  \command{\link{weather}}.
}
\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

% options(error=recover)
% source("RandomFields/tests/source.R")

## currently disabled!

\dontshow{\dontrun{

## See also  papers.jss14.rd !!!!

RFoptions(modus_operandi="sloppy")


#########################################################
## simulate some data first
points <- 100
x <- runif(points, 0, 3)
y <- runif(points, 0, 3) ## random points in square [0, 3]^2
model <- RMgencauchy(alpha=1, beta=2)
d <- RFsimulate(model, x=x, y=y, grid=FALSE, n=n=100) #better n=1000


#########################################################
## estimation; 'NA' means: "to be estimated"
estmodel <- RMgencauchy(var=NA, scale=NA, alpha=NA, beta=2) +
            RMtrend(mean=NA)
RFcrossvalidate(estmodel, data=d)

}}

\dontshow{RFoptions(modus_operandi="normal")}
\dontshow{FinalizeExample()}}

\keyword{spatial}

