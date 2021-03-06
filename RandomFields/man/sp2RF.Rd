\name{sp2RF}
\alias{sp2RF}
\title{Transformation of an 'sp' object to an 'RFsp' object}
\description{
  The function transforms an 'sp' object to an 'RFsp' object.

  This explicit transformation is only necessary if several variables and
  repeated measurements are given.
}
\usage{
sp2RF(sp, param=list(n=1, vdim=1)) 
}
\arguments{
  \item{sp}{an \sQuote{sp} object}
  \item{param}{\code{n}: number of repetitions; \code{vdim}: the number of
    variables (multivariability)
  }
}
\value{
 \command{\link{sp2RF}} returns an object of class
 \code{\link[=RFsp-class]{RFsp}}. 
}

\note{The two options \code{varnames} and \code{coordnames},
  cf. section \sQuote{coords} in \command{\link{RFoptions}},
  might be useful.}

\me
\seealso{
  \command{\link[=RFsp-class]{RFsp}}
}


\keyword{spatial}


\examples{\dontshow{StartExample(reduced=FALSE)}
RFoptions(seed=0) ## *ANY* simulation will have the random seed 0; set
##                   RFoptions(seed=NA) to make them all random again

p <- 100
n <- 5
x <- runif(p, 0, 1)
y <- runif(p, 0, 1)
z <- RFsimulate(RMexp(), x=x, y=y, n=n)
z1 <- z2 <- as.data.frame(z)
coordinates(z2) <- ~coords.x1 + coords.x2

(emp.var <- RFvariogram(data=z))
(emp.var1 <- RFvariogram(data=z1))
(emp.var2 <- RFvariogram(data=sp2RF(z2, param=list(n=n, vdim=1))))

stopifnot(all.equal(emp.var, emp.var1))
stopifnot(all.equal(emp.var, emp.var2))
\dontshow{FinalizeExample()}
}
