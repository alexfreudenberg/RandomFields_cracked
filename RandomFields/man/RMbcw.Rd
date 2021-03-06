\name{RMbcw}
\alias{RMbcw}

\title{Model bridging stationary and intrinsically stationary processes}
\description{
  \command{\link{RMbcw}} is a variogram model
  that bridges between some intrinsically stationary isotropic processes
  and some stationary ones. It reunifies the
  \command{\link{RMgenfbm}} \sQuote{b}, \command{\link{RMgencauchy}} \sQuote{c}
  and \command{\link{RMdewijsian}} \sQuote{w}.

 The corresponding centered semi-variogram only depends on the distance
 \eqn{r \ge 0}{r \ge 0} between two points and is given by
 \deqn{\gamma(r) =
   \frac{(r^{\alpha}+1)^{\beta/\alpha}-1}{2^{\beta/\alpha} -1}}{
   \gamma(r)=[(r^{\alpha}+1)^{\beta/\alpha}-1] / (2^{\beta/\alpha}-1)}
 where \eqn{\alpha \in (0,2]}{0 < \alpha \le 2} and \eqn{\beta \le 2}{\beta <= 2}.\cr
}
\usage{
RMbcw(alpha, beta, const, var, scale, Aniso, proj)
}
\arguments{
 \item{alpha}{a numerical value; should be in the interval (0,2].}
 \item{beta}{a numerical value; should be in the interval (-infty,2].}
 \item{const}{only for experts. If given, a not necessarily positive definite
 function \eqn{const-\gamma(r)} is built.}
 \item{var,scale,Aniso,proj}{optional arguments; same meaning for any
 \command{\link{RMmodel}}. If not passed, the above
 variogram remains unmodified.}
}
\details{
  For \eqn{\beta >0}, \eqn{\beta<0}, \eqn{\beta=0}
  we have the generalized fractal Brownian motion \command{\link{RMgenfbm}},
  the generalized Cauchy model \command{\link{RMgencauchy}},
  and the de Wisjian model \command{\link{RMdewijsian}}, respectively.

  Hence its two arguments \code{alpha} and \code{beta}
  allow for modelling the smoothness and a wide range of tail behaviour,
  respectively. 
  
}
\value{
 \command{\link{RMbcw}} returns an object of class \code{\link[=RMmodel-class]{RMmodel}}

}
\references{
 \itemize{
 \item Schlather, M (2014) A parametric variogram model bridging
 between stationary and intrinsically stationary processes. \emph{arxiv}
 \bold{1412.1914}.
 % \item Martin's Toledo-Chapter: Construction of covariance functions
 % and unconditional simulation of random fields, Application to variograms
 }
}


\me
\seealso{
  \command{\link{RMlsfbm}} is equipped with Matheron's constant \eqn{c} for
  the fractional brownian motion,
  \command{\link{RMgenfbm}},
  \command{\link{RMgencauchy}},
  \command{\link{RMdewijsian}},
  \command{\link{RMmodel}},
  \command{\link{RFsimulate}},
  \command{\link{RFfit}}.
}


\keyword{spatial}
\keyword{models}


\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

model <- RMbcw(alpha=1, beta=0.5)
x <- seq(0, 10, 0.02)
plot(model)
plot(RFsimulate(model, x=x))
\dontshow{FinalizeExample()}}