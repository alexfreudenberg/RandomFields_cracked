\name{RMdelay}
\alias{RMdelay}
\title{Bivariate Delay Effect}
\description{
 \command{\link{RMdelay}} is a \eqn{(m+1)}-variate stationary covariance model.
 which depends on a univariate stationary covariance model \eqn{C_0}.
 
 The corresponding covariance function only depends on the difference
 \eqn{h \in {\bf R}^d}{h} between two points in \eqn{d}-dimensional
 space and is given by
 \deqn{C(h)=(C_0(h - s_i +s_j))_{i,j=0,\ldots,m}}
 where \eqn{s \in {\bf R}^{d\times m}}{h \in R^{d x m}} and \eqn{s_0=0}
}

\usage{
RMdelay(phi,s,var, scale, Aniso, proj)
}
\arguments{
 \item{phi}{a univariate stationary covariance model, that means an
 \command{\link{RMmodel}} whose \command{vdim} equals 1.}
 \item{s}{a \eqn{d\times m}{d x m}-dimensional
 shift matrix, where \eqn{d} is the
 dimension of the space, giving the components \eqn{s=(s_1,\ldots,
 s_m)}{s=(s_1,..., s_m)} where the \eqn{s_i} are vectors.}
 \item{var,scale,Aniso,proj}{optional arguments; same meaning for any
 \command{\link{RMmodel}}. If not passed, the above
 covariance function remains unmodified.}
}
\details{%See Wackernagel, H. (2003), p.?)
 Here, a multivariate random field is obtained from a single univariate
 random field by shifting it by a fixed value.
}
\value{
 \command{\link{RMdelay}} returns an object of class \code{\link[=RMmodel-class]{RMmodel}}.
}
\references{
 \itemize{
 \item Schlather, M., Malinowski, A., Menck, P.J., Oesting, M. and
    Strokorb, K. (2015) 
    Analysis, simulation and prediction of multivariate
    random fields with package \pkg{RandomFields}. \emph{
      Journal of Statistical Software}, \bold{63} (8), 1-25,
    url          = \sQuote{http://www.jstatsoft.org/v63/i08/}
 \item Wackernagel, H. (2003) \emph{Multivariate Geostatistics.} Berlin:
 Springer, 3nd edition.
 }
}

\me
\seealso{
 \command{\link{RMmodel}},
 \command{\link{RFsimulate}},
 \command{\link{RFfit}}.
}

\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

x <- y <- seq(-10,10,0.2)
model <- RMdelay(RMstable(alpha=1.9, scale=2), s=c(4,4))
plot(model, dim=2, xlim=c(-6, 6), ylim=c(-6,6))

simu <- RFsimulate(model, x, y)
plot(simu, zlim="joint")

\dontshow{FinalizeExample()}}


\keyword{spatial}
\keyword{models}


