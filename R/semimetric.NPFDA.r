#####################################################################
#####################################################################
#####################################################################
mplsr <- function(X, Y, K = 5,...)
{
# Copyright (c) October 1993, Mike Denham.
# Comments and Complaints to: snsdenhm@reading.ac.uk
#
# Orthogonal Scores Algorithm for PLS (Martens and Naes, pp. 121--123)
#
# X: predictors (matrix)
#
# Y: multivariate response (matrix)
#
# K: The number of PLS factors in the model which must be less than or
#    equal to the  rank of X.
#
# Returned Value is the vector of PLS regression coefficients
#
	tol <- 1e-10
	X <- as.matrix(X)
	Y <- as.matrix(Y)
	dx <- dim(X)
	nbclass <- ncol(Y)
	xbar <- apply(X, 2, sum)/dx[1]
	ybar <- apply(Y, 2, sum)/dx[1]
	X0 <- X - outer(rep(1, dx[1]), xbar)
	Y0 <- Y - outer(rep(1, dx[1]), ybar)
	W <- matrix(0, dx[2], K)
	P <- matrix(0, dx[2], K)
	Q <- matrix(0, nbclass, K)
	sumofsquaresY <- apply(Y0^2, 2, sum)
	u <- Y0[, order(sumofsquaresY)[nbclass]]
	tee <- 0
	for(i in 1:K) {
		test <- 1 + tol
		while(test > tol) {
			w <- crossprod(X0, u)
			w <- w/sqrt(crossprod(w)[1])
			W[, i] <- w
			teenew <- X0 %*% w
			test <- sum((tee - teenew)^2)
			tee <- teenew
			cee <- crossprod(tee)[1]
			p <- crossprod(X0, (tee/cee))
			P[, i] <- p
			q <- crossprod(Y0, tee)[, 1]/cee
			u <- Y0 %*% q
			u <- u/crossprod(q)[1]
		}
		Q[, i] <- q
		X0 <- X0 - tee %*% t(p)
		Y0 <- Y0 - tee %*% t(q)
	}
	COEF <- W %*% solve(crossprod(P, W)) %*% t(Q)
	b0 <- ybar - t(COEF) %*% xbar
	list(b0 = b0, COEF = COEF)
}
#####################################################################
#####################################################################
#####################################################################
hshift <- function(x,y, t=1:ncol(x),...)
{
####################################################################
# Returns the "horizontal shifted proximity" between two discretized
# curves "x" and "y" (vectors of same length).
# The user has to choose a "t".
#####################################################################
  lgrid <- length(t)
	a <- t[1]
	b <- t[lgrid]
	rang <- b - a
  lagmax <- floor(0.2 * rang)
	integrand <- (x-y)^2
	Dist1 <- sum(integrand[-1] + integrand[-lgrid])/(2 * rang)
	Dist2 <- Dist1
	for(i in 1:lagmax){
	        xlag <- x[-(1:i)]
		xforward <- x[-((lgrid-i+1):lgrid)]
	        ylag <- y[-(1:i)]
		yforward <- y[-((lgrid-i+1):lgrid)]
		integrand1 <- (xlag-yforward)^2
		integrand2 <- (xforward-ylag)^2
		lintegrand <- length(integrand1)
		rescaled.range <- 2 * (rang - 2 * i)
		Dist1[i+1] <- sum(integrand1[-1] + integrand1[-lintegrand])/rescaled.range
		Dist2[i+1] <- sum(integrand2[-1] + integrand2[-lintegrand])/rescaled.range
        }
	lag1 <- (0:lagmax)[order(Dist1)[1]]
	lag2 <- (0:lagmax)[order(Dist2)[1]]
	distmin1 <- min(Dist1)
	distmin2 <- min(Dist2)
	if(distmin1 < distmin2){
		distmin <- distmin1
		lagopt <- lag1
	}else{
		distmin <- distmin2
		lagopt <- lag2
	}
	return(list(dist=sqrt(distmin),lag=lagopt))
}
#####################################################################
#####################################################################
#####################################################################
semimetric.deriv <- function(fdataobj1,fdataobj2, nderiv=1,
nknot=ifelse(floor(ncol(DATA1)/3) > floor((ncol(DATA1) - nderiv - 4)/2),
floor((ncol(DATA1) - nderiv - 4)/2), floor(ncol(DATA1)/3)),range.t=c(0,1),...)
{
###############################################################
# Computes a semimetric between curves based on their derivatives.
#    "DATA1" matrix containing a first set of curves stored row by row
#    "DATA2" matrix containing a second set of curves stored row by row
#    "nderiv" order of derivation
#    "nknot" number of interior knots (needed for defining the B-spline basis)
#    "range.t" vector of length 2 containing the range of the grid at
#                 which the curve are evaluated (i.e. range of the
#                 discretization)
# Returns a "semimetric" matrix containing the semimetric computed
# between the curves lying to the first sample and the curves lying
# to the second one.
###############################################################
#	library(splines)
 if (!is.fdata(fdataobj1)) fdataobj1<-fdata(fdataobj1)
 tt<-fdataobj1[["argvals"]]
 nas1<-apply(fdataobj1$data,1,count.na)
 if (any(nas1))  stop("fdata1 contain ",sum(nas1)," curves with some NA value \n")
 else  if (!is.fdata(fdataobj2))  {fdataobj2<-fdata(fdataobj2,tt) }
 nas2<-apply(fdataobj2$data,1,count.na)
 if (any(nas2))  stop("fdata2 contain ",sum(nas2)," curves with some NA value \n")


DATA1<-fdataobj1[["data"]]
DATA2<-fdataobj2[["data"]]
	testfordim <- sum(dim(DATA1)==dim(DATA2))==2
	twodatasets <- TRUE
	if(testfordim) twodatasets <- sum(DATA1==DATA2)!=prod(dim(DATA1))
#####################################################################
# B-spline approximation of the curves containing in DATASET :
# -----------------------------------------------------------
# "knot" and "x" allow to define the B-spline basis
# "coef.mat1[, i]" corresponds to the B-spline expansion
# of the discretized curve contained in DATASET[i, ].
# The B-spline approximation of the curve contained in "DATA1[i, ]"
# is given by "Bspline %*% coef.mat1[, i]"
#####################################################################
	C1<-match.call()
  p <- ncol(DATA1)
	a <- range.t[1]
	b <- range.t[2]
	x <- seq(a, b, length = p)
	order.Bspline <- nderiv + 3
	nknotmax <- (p - order.Bspline - 1)%/%2
	if(nknot > nknotmax){
		stop(paste("give a number nknot smaller than ",nknotmax, " for avoiding ill-conditioned matrix"))
	}
	Knot <- seq(a, b, length = nknot + 2)[ - c(1, nknot + 2)]
	delta <- sort(c(rep(c(a, b), order.Bspline), Knot))
	Bspline <- splineDesign(delta, x, order.Bspline)
	Cmat <- crossprod(Bspline)
	Dmat1 <- crossprod(Bspline, t(DATA1))
	coef.mat1 <- symsolve(Cmat, Dmat1)
#######################################################################
# Numerical integration by the Gauss method :
# -------------------------------------------
# The objects ending by "gauss" allow us to compute numerically
# integrals by means the "Gauss method" (lx.gauss=6 ==> the computation
# of the integral is exact for polynom of degree less or equal to 11).
#######################################################################
	point.gauss <- c(-0.9324695142, -0.6612093865, -0.2386191861,
		0.2386191861, 0.6612093865, 0.9324695142)
	weight.gauss <- c(0.1713244924, 0.360761573, 0.4679139346, 0.4679139346,0.360761573, 0.1713244924)
	x.gauss <- 0.5 * ((b + a) + (b - a) * point.gauss)
	lx.gauss <- length(x.gauss)
	Bspline.deriv <- splineDesign(delta, x.gauss, order.Bspline, rep(nderiv, lx.gauss))
	H <- t(Bspline.deriv) %*% (Bspline.deriv * (weight.gauss * 0.5 * (b - a)))
	eigH <- eigen(H, symmetric = TRUE)
	eigH$values[eigH$values < 0] <- 0
	Hhalf <- t(eigH$vectors %*% (t(eigH$vectors) * sqrt(eigH$values)))
	COEF1 <- t(Hhalf %*% coef.mat1)
	if(twodatasets){
		Dmat2 <- crossprod(Bspline, t(DATA2))
		coef.mat2 <- symsolve(Cmat, Dmat2)
		COEF2 <- t(Hhalf %*% coef.mat2)
	} else {
		COEF2 <- COEF1
	}
	SEMIMETRIC <- 0
	nbasis <- nrow(H)
	for(f in 1:nbasis)
		SEMIMETRIC <- SEMIMETRIC + outer(COEF1[, f], COEF2[, f], "-")^2
  mdist<-sqrt(SEMIMETRIC)
  attr(mdist,"call")<-C1
	return(mdist)
}
#####################################################################
#####################################################################
#####################################################################
semimetric.fourier <- function(fdataobj1,fdataobj2, nderiv=0,
nbasis=ifelse(floor(ncol(DATA1)/3) > floor((ncol(DATA1) - nderiv - 4)/2),
floor((ncol(DATA1) - nderiv - 4)/2), floor(ncol(DATA1)/3)), range.t=c(0,1), period=NULL,...)
{
###############################################################
# Computes a semimetric between curves based on their Fourier expansion.
#    "DATA1" matrix containing a first set of curves stored row by row
#    "DATA2" matrix containing a second set of curves stored row by row
#    "nderiv" order of derivation
#    "nbasis" size of the basis
#    "range.t" vector of length 2 containing the range of the grid at
#                 which the curve are evaluated (i.e. range of the
#                 discretization)
#    "period" allows to select the period for the fourier expansion
# Returns a "semimetric" matrix containing the semimetric computed
# between the curves lying to the first sample and the curves lying
# to the second one.
###############################################################
C1<-match.call()
 if (!is.fdata(fdataobj1)) fdataobj1<-fdata(fdataobj1)
 tt<-fdataobj1[["argvals"]]
 nas1<-apply(fdataobj1$data,1,count.na)
 if (any(nas1))  stop("fdata1 contain ",sum(nas1)," curves with some NA value \n")
 else  if (!is.fdata(fdataobj2))  {fdataobj2<-fdata(fdataobj2,tt) }
 nas2<-apply(fdataobj2$data,1,count.na)
 if (any(nas2))  stop("fdata2 contain ",sum(nas2)," curves with some NA value \n")

DATA1<-fdataobj1[["data"]]
DATA2<-fdataobj2[["data"]]
	p <- ncol(DATA1)
	nbasismax <- (p - nbasis)%/%2
	if(nbasis > nbasismax){
		stop(paste("give a number nbasis smaller than ",nbasismax, " for avoiding ill-conditioned matrix"))
	}
	testfordim <- sum(dim(DATA1)==dim(DATA2))==2
	twodatasets <- TRUE
	if(testfordim) twodatasets <- sum(DATA1==DATA2)!=prod(dim(DATA1))
	a <- range.t[1]
	b <- range.t[2]
	Eval <- seq(a, b, length = p)
#####################################################################
# Fourier approximation of the curves containing in DATA1 :
# -----------------------------------------------------------
# "fourier" allows to define the Fourier basis
# "COEF1[, i]" corresponds to the Fourier expansion
# of the discretized curve contained in DATA1[i, ].
# The Fourier approximation of the curve contained in "DATA1[i, ]"
# is given by "FOURIER %*% COEF1[, i]"
#####################################################################
        if(is.null(period)) period <- b - a
	FOURIER <- fourier(Eval, nbasis, period)
	CMAT <- crossprod(FOURIER)
	DMAT1 <- crossprod(FOURIER, t(DATA1))
	COEF1 <- symsolve(CMAT, DMAT1)
#######################################################################
# Numerical integration by the Gauss method :
# -------------------------------------------
# The objects ending by "gauss" allow us to compute numerically
# integrals by means the "Gauss method" (Leval.gauss=6 ==> the computation
# of the integral is exact for polynom of degree less or equal to 11).
#######################################################################
	Point.gauss <- c(-0.9324695142, -0.6612093865, -0.2386191861,
		0.2386191861, 0.6612093865, 0.9324695142)
	Weight.gauss <- c(0.1713244924, 0.360761573, 0.4679139346, 0.4679139346,
		0.360761573, 0.1713244924)
	Eval.gauss <- 0.5 * (b - a) * (1 + Point.gauss)
	Leval.gauss <- length(Eval.gauss)
	FOURIER.DERIV <- fourier(Eval.gauss, nbasis, period, nderiv)
	H <- t(FOURIER.DERIV) %*% (FOURIER.DERIV * (Weight.gauss * 0.5 * (b - a
		)))
	eigH <- eigen(H, symmetric = TRUE)
	eigH$values[eigH$values < 0] <- 0
	HALF <- t(eigH$vectors %*% (t(eigH$vectors) * sqrt(eigH$values)))
	COEF1 <- t(HALF %*% COEF1)
	if(twodatasets) {
		DMAT2 <- crossprod(FOURIER, t(DATA2))
		COEF2 <- symsolve(CMAT, DMAT2)
		COEF2 <- t(HALF %*% COEF2)
	}
	else {
		COEF2 <- COEF1
	}
	SEMIMETRIC <- 0
	for(f in 1:nbasis)
		SEMIMETRIC <- SEMIMETRIC + outer(COEF1[, f], COEF2[, f], "-")^2
  mdist<-sqrt(SEMIMETRIC)
  attr(mdist,"call")<-C1
	return(mdist)
}
#####################################################################
#####################################################################
#####################################################################
semimetric.hshift <- function(fdataobj1,fdataobj2, t=1:ncol(DATA1),...)
{
###############################################################
# Computes between curves a semimetric taking into account an
# horizontal shift effect.
#    "DATA1" matrix containing a first set of curves stored row by row
#    "DATA2" matrix containing a second set of curves stored row by row
#    "t" vector which defines the grid (one can choose 1,2,...,nbgrid
#           where nbgrid is the number of points of the discretization)
# Returns a "semimetric" matrix containing the semimetric computed
# between the curves lying to the first sample and the curves lying
# to the second one.
###############################################################
C1<-match.call()
 if (!is.fdata(fdataobj1)) fdataobj1<-fdata(fdataobj1)
 tt<-fdataobj1[["argvals"]]
 nas1<-apply(fdataobj1$data,1,count.na)
 if (any(nas1))  stop("fdata1 contain ",sum(nas1)," curves with some NA value \n")
 else  if (!is.fdata(fdataobj2))  {fdataobj2<-fdata(fdataobj2,tt) }
 nas2<-apply(fdataobj2$data,1,count.na)
 if (any(nas2))  stop("fdata2 contain ",sum(nas2)," curves with some NA value \n")

DATA1<-fdataobj1[["data"]]
DATA2<-fdataobj2[["data"]]
	testfordim <- sum(dim(DATA1)==dim(DATA2))==2
	twodatasets <- TRUE
	if(testfordim) twodatasets <- sum(DATA1==DATA2)!=prod(dim(DATA1))
	n1 <- nrow(DATA1)
	if(twodatasets) n2 <- nrow(DATA2) else n2 <- n1
	SEMIMETRIC <- matrix(0, nrow=n1, ncol=n2)
	if(!twodatasets){
		for(i in 1:(n1-1)){
			for(j in (i+1):n2){
				SEMIMETRIC[i,j] <- hshift(DATA1[i,], DATA2[j,], t)$dist
			}
		}
		SEMIMETRIC <- SEMIMETRIC + t(SEMIMETRIC)
	}else{
		for(i in 1:n1){
			for(j in 1:n2){
				SEMIMETRIC[i,j] <- hshift(DATA1[i,], DATA2[j,], t)$dist
			}
		}
	}
  mdist<-sqrt(SEMIMETRIC)
  attr(mdist,"call")<-C1
	return(mdist)
}
#####################################################################
#####################################################################
#####################################################################
semimetric.mplsr <- function(fdataobj1,fdataobj2, q=2, class1,...)
{
###############################################################
# Computes between curves a semimetric based on the partial least
# squares method.
#    "DATA1" matrix containing a first set of curves stored row by row
#    "DATA2" matrix containing a second set of curves stored row by row
#    "q" the retained number of factors
#    "class1" vector containing a categorical response which
#              corresponds to class number for units stored in DATA1
# Returns a "semimetric" matrix containing the semimetric computed
# between the curves lying to the first sample and the curves lying
# to the second one.
###############################################################
C1<-match.call()
 if (!is.fdata(fdataobj1)) fdataobj1<-fdata(fdataobj1)
 tt<-fdataobj1[["argvals"]]
 nas1<-apply(fdataobj1$data,1,count.na)
 if (any(nas1))  stop("fdata1 contain ",sum(nas1)," curves with some NA value \n")
 else  if (!is.fdata(fdataobj2))  {fdataobj2<-fdata(fdataobj2,tt) }
 nas2<-apply(fdataobj2$data,1,count.na)
 if (any(nas2))  stop("fdata2 contain ",sum(nas2)," curves with some NA value \n")

DATA1<-fdataobj1[["data"]]
DATA2<-fdataobj2[["data"]]
	testfordim <- sum(dim(DATA1)==dim(DATA2))==2
	twodatasets <- TRUE
	if(testfordim) twodatasets <- sum(DATA1==DATA2)!=prod(dim(DATA1))
	qmax <- ncol(DATA1)
	if(q > qmax) stop(paste("give a integer q smaller than ", qmax))
	n1 <- nrow(DATA1)
	if (is.factor(class1)) class1=as.numeric(class1)
	nbclass <- max(class1)
	BINARY1 <- matrix(0, nrow = n1, ncol = nbclass)
	for(g in 1:nbclass) {
		BINARY1[, g] <- as.numeric(class1 == g)
	}
	mplsr.res <- mplsr(DATA1, BINARY1, q)
	COMPONENT1 <- DATA1 %*% mplsr.res$COEF
	COMPONENT1 <- outer(rep(1, n1), as.vector(mplsr.res$b0)) + COMPONENT1
	if(twodatasets) {
		n2 <- nrow(DATA2)
		COMPONENT2 <- DATA2 %*% mplsr.res$COEF
		COMPONENT2 <- outer(rep(1, n2), as.vector(mplsr.res$b0)) +
			COMPONENT2
	}
	else {
		COMPONENT2 <- COMPONENT1
	}
	SEMIMETRIC <- 0
	for(g in 1:nbclass)
		SEMIMETRIC <- SEMIMETRIC + outer(COMPONENT1[, g], COMPONENT2[,
			g], "-")^2
  mdist<-sqrt(SEMIMETRIC)
  attr(mdist,"call")<-C1
	return(mdist)
}
#####################################################################
#####################################################################
#####################################################################
semimetric.pca <- function(fdataobj1, fdataobj2, q=1,...)
{
###############################################################
# Computes between curves a pca-type semimetric based on the
# functional principal components analysis method.
#    "DATA1" matrix containing a first set of curves stored row by row
#    "DATA2" matrix containing a second set of curves stored row by row
#    "q" the retained number of principal components
# Returns a "semimetric" matrix containing the semimetric computed
# between the curves lying to the first sample and the curves lying
# to the second one.
###############################################################
C1<-match.call()
 if (!is.fdata(fdataobj1)) fdataobj1<-fdata(fdataobj1)
 tt<-fdataobj1[["argvals"]]
 nas1<-apply(fdataobj1$data,1,count.na)
 if (any(nas1))  stop("fdata1 contain ",sum(nas1)," curves with some NA value \n")
 else  if (!is.fdata(fdataobj2))  {fdataobj2<-fdata(fdataobj2,tt) }
 nas2<-apply(fdataobj2$data,1,count.na)
 if (any(nas2))  stop("fdata2 contain ",sum(nas2)," curves with some NA value \n")

DATA1<-fdataobj1[["data"]]
DATA2<-fdataobj2[["data"]]
#	if(is.vector(DATA1)) DATA1 <- as.matrix(t(DATA1))
#	if(is.vector(DATA2)) DATA2 <- as.matrix(t(DATA2))
	testfordim <- sum(dim(DATA1)==dim(DATA2))==2
	twodatasets <- TRUE
	if(testfordim) twodatasets <- sum(DATA1==DATA2)!=prod(dim(DATA1))
	qmax <- ncol(DATA1)
	if(q > qmax) stop(paste("give a integer q smaller than ", qmax))
	n <- nrow(DATA1)
	COVARIANCE <- t(DATA1) %*% DATA1/n
	ei=eigen(COVARIANCE, symmetric = TRUE)
	EIGENVECTORS <- matrix(eigen(COVARIANCE, symmetric = TRUE)$vectors[, 1:q],ncol=q)
	COMPONENT1 <- DATA1 %*% EIGENVECTORS
	if(twodatasets) {
		COMPONENT2 <- DATA2 %*% EIGENVECTORS
	}
	else {
		COMPONENT2 <- COMPONENT1
	}
	SEMIMETRIC <- 0
	for(qq in 1:q)
		SEMIMETRIC <- SEMIMETRIC + outer(COMPONENT1[, qq], COMPONENT2[,
			qq], "-")^2
#			print(dim(SEMIMETRIC))
  mdist<-sqrt(SEMIMETRIC)
  attr(mdist,"call")<-C1
	return(mdist)
}
#####################################################################
#####################################################################
#####################################################################



