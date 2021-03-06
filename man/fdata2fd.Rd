\name{fdata2fd}
\Rdversion{1.1}
\alias{fdata2fd}
\title{ Converts fdata class object into fd class object
}
\description{
 Converts \code{fdata} class object into \code{fd} class object using \code{Data2fd} function.
}
\usage{
fdata2fd(fdataobj,type.basis=NULL,nbasis=NULL,nderiv=0,
lambda=NULL,...)
}

\arguments{
   \item{fdataobj}{ \code{\link{fdata}} class object.} 
   \item{type.basis}{ Type of basis. A function \code{create."type.basis".basis}  must exists. By default, \code{bspline} basis is used.} 
   \item{nbasis}{ Number of basis which is used in \code{create.basis} function.}  
   \item{nderiv}{  Order of derivation which is used in \code{deriv.fd} function (optional).} 
   \item{lambda}{ Weight on the smoothing operator specified by \code{nderiv}.}
  \item{\dots}{ Further arguments passed to or from other methods.}
  }    
\value{
Return  an object of the \code{fd} class.
}
\author{
Manuel Febrero-Bande, Manuel Oviedo de la Fuente \email{manuel.oviedo@usc.es}
}
\seealso{
See Also as \code{\link{fdata}} and \code{\link{Data2fd}}
}
\references{
Febrero-Bande,  M., Oviedo de la Fuente, M. (2012).  \emph{Statistical Computing in Functional Data Analysis: The R Package fda.usc.}
Journal of Statistical Software, 51(4), 1-28. \url{http://www.jstatsoft.org/v51/i04/}
}
\examples{

data(phoneme)
mlearn<-phoneme$learn[1,]
fdata2=fdata2fd(mlearn)
class(mlearn)
class(fdata2)
fdata3=fdata2fd(mlearn,type.basis="fourier",nbasis=7)
plot(mlearn)
lines(fdata2,col=2)
lines(fdata3,col=3)
fdata5=fdata2fd(mlearn,nderiv=1)

}
\keyword{manip} 