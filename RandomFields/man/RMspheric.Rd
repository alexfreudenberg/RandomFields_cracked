\name{RMspheric}
\alias{RMspheric}
\title{The Spherical Covariance Model}
\description{
 \command{\link{RMspheric}} is a stationary isotropic covariance model
 which is only valid up to dimension 3.
 The corresponding covariance function only depends on the distance
 \eqn{r \ge 0}{r \ge 0} between two points and is given by
 \deqn{C(r) = \left(1 - \frac{3}{2} r + \frac{1}{2} r^3\right)
 1_{[0,1]}(r)}{C(r) = (1 - 1.5 r + 0.5 r^3) 1_{[0,1]}(r).}
}
\usage{
RMspheric(var, scale, Aniso, proj)
}
\arguments{
 \item{var,scale,Aniso,proj}{optional arguments; same meaning for any
 \command{\link{RMmodel}}. If not passed, the above
 covariance function remains unmodified.}
}
\details{
 This covariance model is valid only for dimensions less than or equal
 to 3.

 The covariance function has a finite range.
}
\value{
 \command{\link{RMspheric}} returns an object of class \code{\link[=RMmodel-class]{RMmodel}}.
}
\references{
 Gelfand, A. E., Diggle, P., Fuentes, M. and Guttorp,
 P. (eds.) (2010) \emph{Handbook of Spatial Statistics.}
 Boca Raton: Chapman & Hall/CRL.
 }

\me
 \note{Although this model is valid on a sphere, do not mix up this model
 with valid models on a sphere; see \link{spherical models}
 for a list of the latter.}
\seealso{
 \command{\link{RMmodel}},
 \command{\link{RFsimulate}},
 \command{\link{RFfit}},
 \link{spherical models}.
}


\keyword{spatial}
\keyword{models}

\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

model <- RMspheric()
x <- seq(0, 10, 0.02)
plot(model)
plot(RFsimulate(model, x=x))
\dontshow{FinalizeExample()}}