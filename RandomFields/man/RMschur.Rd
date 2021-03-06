\name{RMschur}
\alias{RMschur}
\title{Schur product}
\description{
 The covariance function is

 \deqn{C(x)= M * \phi(x)}

 where \sQuote{*} denotes the Schur product, i.e. elementwise
 multiplication.
 
 }
 \usage{
RMschur(phi, M,  diag, rhored, var, scale, Aniso, proj)
}

\arguments{
 \item{phi}{covariance function of class \code{\link[=RMmodel-class]{RMmodel}}}
 \item{M}{constant \eqn{n \times n}{n x n} covariance matrix of the
   same size as multivariate model \code{phi}}
 \item{diag,rhored}{alternative way of passing \code{M}:
   \code{diag} is a vector of variances, \code{rhored} is a vector
   containing the correlations of the lower triangle of the \code{M}.
 }
 \item{var,scale,Aniso,proj}{optional arguments; same meaning for any
 \command{\link{RMmodel}}. If not passed, the above
 covariance function remains unmodified.}
}

\value{
 \command{\link{RMschur}} returns an object of class \code{\link[=RMmodel-class]{RMmodel}}.

}

\references{
\itemize{
 \item ?
 }
}

\me
\seealso{
 \command{\link{RMmodel}},
 \command{\link{RMmatrix}}.
 }


\keyword{spatial}
\keyword{models}




\examples{\dontshow{StartExample()}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again
model <- RMschur(M=matrix(c(2, 1, 1, 1), ncol=2), RMparswm(nudiag=c(0.5, 2)))
plot(model)
x <- seq(0, 10, 0.02)
plot(RFsimulate(model, x=x))
\dontshow{FinalizeExample()}}