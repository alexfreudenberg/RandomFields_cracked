## Authors 
## Martin Schlather, schlather@math.uni-mannheim.de
##
##
## Copyright (C) 2015 -- 2017 Martin Schlather
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 3
## of the License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.  


## source("modelling.R")




predictGauss <- function(Reg,
                         Reg.predict= if (missing(model)) Reg else
                         RFopt$register$predict_register,
                         model, x, y = NULL, z = NULL, T=NULL, grid=NULL,
                         data, distances, dim, kriging_variance, ...) {
  RFoptOld <- internal.rfoptions(...)
  on.exit(RFoptions(LIST=RFoptOld[[1]]))
  RFopt <- RFoptOld[[2]]

  if (missing(model) || is.null(model)) {
    ## no measurement errors
    if (Reg != Reg.predict) stop("'Reg.predict' may not be given.")
    model <- list("predict", register=Reg)
  } else {
    ## here, 'Reg' contains a measurement structure, and model is without it
    if (Reg == Reg.predict) stop("'Reg.predict' must be different from 'Reg'")
    model <- list("predict", model, register=Reg)

    ## to do : warum nachfolgendes? hat doch keine Wirkung!?
    splittingC <- function(model, preceding, factor) {
      const <- sapply(model[-1],
                      function(m) (is.numeric(m) && !is.na(m)) ||
                                  (m[[1]] == R_CONST && !is.na(m[[2]]))
                      )
      if (all(const)) {
        model <- c(model[1], if (preceding > 0) rep(0, preceding), model[-1])
        return(list(SYMBOL_MULT, model, if (!missing(factor)) list(factor)))
      }
      for (i in 2:length(model)) {
        vdim <- preceding + (if (i==2) 0 else GetDimension(model[[i-1]]))
        m  <- ReplaceC(model[[i]])
        L <- GetDimension(m)
        model[[i]] <- setvector(m, preceding = vdim, len = L, factor=factor)
      }
      model[[1]] <- SYMBOL_PLUS
      names(model) <- NULL
      L <- GetDimension(model[[length(model)]])
      model <- SetDimension(model, L)
    }
  }
  rfInit(model=model, x=x, y=y, z=z, T=T, grid=grid,
         distances=distances, dim=dim, reg = Reg.predict, RFopt=RFopt)

  .Call(C_EvaluateModel, double(0), as.integer(Reg.predict))
}




GetModelEffects <- function(Z) {
  .Call(C_SetAndGetModelLikelihood, MODEL_AUX,
        list("RFloglikelihood", data = Z$data, Z$model),
        Z$C_coords, original_model)$effect
}



ModelAbbreviations <- function(model){
  L <- length(model)
  N <- character(L)
  ##Print(model)
  for (mm in 1:L) {
    m <- unlist(model[[mm]])
    dollar <- m==DOLLAR[1] | m==DOLLAR[2]
    idx <- which( names(m) != "" & !dollar) ## names(m):names of parameters
##    Print(m, mm, dollar, idx, names(m))
    for (s in which(dollar)) {
##      Print(s, which(idx > s))
      z <- idx[min(which(idx > s))] ## to which model belongs the dollar param?
      m[s] <- m[z] ## put the name of subsequent model in position of dollar pos
      m <- m[-z] ## delete subseqeuent model
    }
    idx <- names(m) != ""
    m[idx] <- paste(names(m)[idx], m[idx], sep="=")
    N[mm] <- paste(abbreviate(m), collapse =".")
##    Print(idx, m, N)
  }
  return(N)
}


ModelParts <- function(model, effects, complete) { ## model immer schon aufbrtt
  ## wird in kriging und in RFfit.R aufgerufen!!
  
  ## model <- P repareModel2(model) 13.7.19
  model <- if ((model[[1]] %in% SYMBOL_PLUS)) model[-1] else list(model)
  if (complete) {
    return(model[effects >= RandomEffect])
  } else {
    err <- model[effects == ErrorEffect]
    if (length(err) == 1) err <- err[[1]]
    else if (length(err) == 0) err <- NULL
    else err <- c(SYMBOL_PLUS, err)
    
    m <- model[ effects == RandomEffect ]
    if (length(m) > 0) {
      if (length(m) == 1) m <- m[[1]] else m <- c(SYMBOL_PLUS, m)
      return(list(model=m, err.model=err))
    } else {
      return(list(model=err, err.model=NULL))
    }
  }
}




FinImputIntern <- function(data, simu, coords, coordnames, data.column, vdim,
                           spConform, fillall=FALSE) {
  data <- data.matrix(data)
  n <- length(data) / (vdim * coords$restotal)
  if (is(data, "RFsp")) {
    if (spConform) {
      data@data[ , ] <- as.vector(simu)
      return(data)
    } else {
      values <- as.matrix(data@data)
      values[is.na(values) | fillall] <- simu
      return(cbind(coordinates(data), values))
    }
  } else { ## not RFsp
    #Print("for testing")
    if (coords$grid) {
      ## to do
      stop("not programmed yet")
    } else {
      ##  coords <- all$x
      colnames(coords$x) <- coordnames
      
      values <- data[, data.column]
      values[is.na(values) | fillall] <- simu
      
      if (!spConform)  return(cbind(coords$x, values))
      
      tmp.all <- conventional2RFspDataFrame(data=values, coords=coords$x,
                                            gridTopology=NULL,
                                            n=n, vdim=vdim,
                                            vdim_close_together=FALSE)
      if (is(tmp.all, "RFspatialPointsDataFrame"))
        Try(tmp.all <- as(tmp.all, "RFspatialGridDataFrame"))
      if (is(tmp.all, "RFpointsDataFrame"))
        Try(tmp.all <- as(tmp.all, "RFgridDataFrame"))
    }
    return(tmp.all)
  }
}


FinishImputing <- function(data, simu, Z, spConform, fillall) {
  ## to do: grid
  is.data <- Z$data.info$is.data
  vdim <- Z$vdim
  if (is.list(data)) {
    for (i in 1:length(data))
      data[[i]] <- FinImputIntern(data=data[[i]], simu=simu[[i]],
                                  coords=Z$coords[[i]], coordnames=Z$coordnames,
                                  data.column=is.data, vdim=vdim,
                                  spConform = spConform, fillall=fillall)
    return(data)
  }

  return(FinImputIntern(data=data, simu=simu, coords=Z$coords[[1]],
                        coordnames=Z$coordnames, data.column=is.data, 
                        vdim=vdim, spConform=spConform, fillall=fillall))

}



ExpandGrid <- function(x) {
  #### ACHTUNG! ZWINGENDE REIHENFOLGE
  if (x$grid) { # 0
    x$x <-
      as.matrix(do.call(expand.grid,
                        lapply(apply(cbind(x$x, x$T), 2,
                                     function(x) list(seq(x[1],by=x[2],length.out=x[3]))), function(x) x[[1]])))
  } else if (x$has.time.comp) {
    dim.x <- if (is.vector(x$x)) c(length(x$x), 1) else dim(x$x)
    x$x <- cbind(matrix(rep(t(x$x), times=x$T[3]),
                            ncol=dim.x[2], byrow=FALSE),
                     rep(seq(x$T[1], by=x$T[2],
                             length.out=x$T[3]), each=dim.x[1]))
  }
  if (length(x$y) > 0) stop("no expansion within a kernel definition")
#  x$y <- double(0) #1 
  x$T <- double(0) #2
  x$grid <- FALSE  #3
#  x$spatialdim <- ncol(x$x) #4
  x$has.time.comp <- FALSE           #5
#  x$di st.given <- FALSE      #6
  x$restotal <- nrow(x$x)   #7
  x$l <- x$restotal         #8
  return(x)
}



rfPrepareData <- function(model, x, y=NULL, z=NULL, T=NULL,
                          distances=NULL, dim, grid,
                          data, given=NULL, params,
                          RFopt, reg, err.model = NULL,
                          err.params, 
                          ...) {
  ## NOTE: if err.model is a list of list, the err.model is
  ## not added to the krige model, but both are taken as they are
  ## internal behaviour to get the random effects with the
  ## existing algorithm!!
  
  if (!missing(distances) && length(distances)>0)
    stop("option distances not programmed yet.")

#  Print(model=model, data=data, given=given, T, ...)
  missing.x <- missing(x) || length(x) == 0
  imputing <- missing.x && (missing(distances) || length(distances) == 0)

  if (!imputing) {
    new <- UnifyXT(x, y, z, T, grid=grid, distances=distances, dim=dim)
    cn <- colnames(new$x)
#    Print(cn)
  #  RFoptions(coord.coordnames=cn)
  }

  ##  Print(model=model, data=data,...)
##  Print(given, data)
  
  if (length(given) == 0) {
    ## so either within the data or the same the x-values
    Z <- UnifyData(model=model, data=data, RFopt=RFopt, params=params, ...)
#Print( data,     Z$matrix.indep.of.x.assumed)
    if (Z$matrix.indep.of.x.assumed) {
      if (missing.x) stop("coordinates cannot be detected")
      Z <- UnifyData(model=model, x=x, y=y, z=z, T=T, RFopt=RFopt,
                     distances=distances, dim=dim, grid=grid,
                     data=data, params=params, ...)
    }
  } else {
 #   Print(missing(given), missing(data),
  #        if (!missing(given)) given, if (!missing(data)) data)
    Z <- UnifyData(model=model, data=data, x=given, RFopt=RFopt,
                   params=params,...)
  }
  model <- krige <- Z$model
  
  if (length(Z$data) != 1) stop("exactly one data set must be given.")
  dim_data <- base::dim(Z$data[[1]])
  Z$data[[1]] <- as.double(Z$data[[1]])
  repet <- Z$repetitions
  new.dim_data <- c(prod(dim_data) / repet, repet)
  base::dim(Z$data[[1]]) <- new.dim_data
  data.na <- is.na(Z$data[[1]])
  data.na.var <- rowSums(data.na)
  base::dim(Z$data[[1]]) <- dim_data
  base::dim(data.na.var) <- c(length(data.na.var) / Z$vdim , Z$vdim)
  data.na.loc <- rowSums(data.na.var > 0) > 0
  any.data.na <- any(data.na.loc)
  split <- any(data.na.var > 0 & data.na.var != repet)

  
  if (any.data.na && Z$coords[[1]]$dist.given)
    stop("missing values not programmed yet for given distancs")

  if (imputing) {
    if (Z$vdim > 1) stop("imputing does not work in the multivariate case")
    if (repet == 1)  {
      if (RFopt$krige$fillall || !any.data.na) {
        data.na <- rep(TRUE, length(data.na)) ## nur
    ## um Daten im Endergebnis einzutragen
        new <- Z$coords[[1]]
      } else {
        new <- ExpandGrid(Z$coords[[1]])
        new$x <- new$x[data.na.loc, , drop=FALSE]
      }
    } else new <- NULL
  } else {
    ## needed in soilRd, in condsimu!!
    ## new <- Z$coords[[1]]  ## why was this set???
  ##  Print(new, UnifyXT(x, y, z, T, grid=grid, distances=distances, dim=dim)); kkkff

##    Print(Z, new, x)
    
    if (Z$tsdim != new$spatialdim + new$has.time.comp)
      stop("coodinate dimension of locations with and without data, ",
           "respectively, do not match.")
  }

  na_rm_lines <- FALSE
  
  if (any.data.na) {
    na_rm_lines <- RFopt$general$na_rm_lines
    if (na_rm_lines && (!imputing || repet==1)) {
      Z$data[[1]] <-  Z$data[[1]][!data.na.loc, , drop=FALSE]
      Z$coords[[1]] <- ExpandGrid(Z$coords[[1]])
      Z$coords[[1]]$x <- Z$coords[[1]]$x[!data.na.loc,  , drop=FALSE]
    } else if (split) {
      data <- list()
      dim(Z$data[[1]]) <-
        c(length(Z$data[[1]]) / (Z$vdim*repet), Z$vdim, repet)
      for (i in 1:repet) data[[i]] <- Z$data[[1]][ , , i, drop=FALSE]
      Z$data <- data
    }
  }
  Z$na_rm_lines <- na_rm_lines

  ## krige enthaelt err.model
  ## model ohne err.model
  if (length(err.model)  == 0) {
    model <- list(model)
  } else if (is(err.model, "RMmodel") ||
             (is.list(err.model) && !is.list(err.model[[1]]))) {
    linpart <- RFlinearpart(model=err.model, params=err.params, new$x, set=1,
                            ...)
    if (length(linpart$X) > 0 || any(linpart$Y != 0))
      stop("a trend is not allowed for the error model.")
    krige <- list(SYMBOL_PLUS,
                  PrepareModel2(err.model, params=err.params, ...,
                                return_transform=FALSE)$model,
                  model)    
    model <- list(model)
  } else if (is.list(err.model) && !is.character(err.model[[1]])) {
    model <- list()
    if (missing(err.params)) err.params <- list()
    for (i in 1:length(err.model)) {
      linpart <- RFlinearpart(model=err.model[[i]], new$x, set=1)
      if (length(linpart$X) > 0 || any(linpart$Y != 0))
        stop("a trend is not allowed for the error model.")
      model[[i]] <-
        PrepareModel2(err.model[[i]], params=err.params[[i]], ...,
                      return_transform = FALSE)$model
    }
  } else if (is.vector(err.model) && length(err.model)==1 && is.na(err.model)
             && missing(err.params)) {
    model <- list(ModelParts(model, effects=GetModelEffects(Z),
                             complete = FALSE)$model)
  } else stop("The argument 'err.model' cannot be interpreted. or 'err.params' is given where it should not")

  
  return(list(Z=Z,  ## given coordinates
              X=new, ## new coordinates
              krige = krige, # model for the matrix to be inverted in SK
              model=model, # model for the vector in SK
              imputing=imputing, data.na = if (imputing) data.na))
}


RFinterpolate <- function(model, x, y=NULL, z=NULL, T=NULL, grid=NULL,
                          distances, dim, data, given=NULL, params,
                          err.model=NULL, err.params, 
                          ignore.trend=FALSE, ...) {
  if (!missing(distances) && length(distances) > 0)
    stop("'distances' not programmed yet.")
    
  opt <- list(...)
  i <- pmatch(names(opt), c("MARGIN"))
  opt <- opt[is.na(i)]
  RFoptOld <- do.call("internal.rfoptions", opt)
  on.exit(RFoptions(LIST=RFoptOld[[1]]))
  RFopt <- RFoptOld[[2]]

  boxcox <- .Call(C_get_boxcox)


  ## eingabe wird anstonsten auch als vdim_close erwartet --
  ## dies ist nocht nicht programmiert! Ausgabe ist schon programmiert
  ## CondSimu ist auch noch nicht programmiert
  if (RFopt$general$vdim_close_together)
    stop("'vdim_close_together' must be FALSE")

  
  reg <- MODEL_KRIGE
  return.variance <- RFopt$krige$return_variance

  all <- rfPrepareData(model=model, x=x, y=y, z=z, T=T,
                       distances=distances, dim=dim, grid=grid,
                       data=data, given=given, params=params, RFopt=RFopt,
                       reg=reg, err.model = err.model, err.params=err.params,
                       ...)
  ##  Print("start", all$Z);
  
  imputing <- all$imputing
  tsdim <- as.integer(all$Z$tsdim)
  repet <- as.integer(all$Z$repetitions)
  vdim <- all$Z$vdim
  if (!imputing) {
    coordnames.incl.T <-
      c(if (!is.null(all$Z$coordnames)) all$Z$coordnames else
        paste(COORD_NAMES_GENERAL[1], 1:all$Z$spatialdim, sep=""),
        if (all$Z$has.time.comp) COORD_NAMES_GENERAL[2] else NULL)
    if (all$X$grid) {
      coords <- list(x=NULL, T=NULL)
      xgr <- cbind(all$X$x, all$X$T)

#      Print(xgr, coordnames.incl.T)
      
      colnames(xgr) <- coordnames.incl.T
      gridTopology <- sp::GridTopology(xgr[1, ], xgr[2, ], xgr[3, ])
      ## bis 3.0.70 hier eine alternative
    } else {
      coords <- list(x=all$X$x, T=all$X$T)
      ## wenn bei gegeben unklar was zu tun ist. Ansonsten
      if (length(coords$T) == 0)  colnames(coords$x) <- coordnames.incl.T
      gridTopology <- NULL
    }
  }
  nx <- all$X$restotal
  dimension <-
    if (all$X$grid) c(if (length(all$X$x) > 0) all$X$x[3, ],
                      if (length(all$X$T) > 0) all$X$T[3]) else nx # to do:grid
  newdim <- c(dimension, if (vdim>1) vdim, if (repet>1) repet)

  if (imputing && return.variance) {
    return.variance <- FALSE
    warning("with imputing, currently the variance cannot be returned")
  }

  L <- length(all$model)
  #Print(length(all$Z$data), all$Z$data)
  if (length(all$Z$data) > 1) {
    Res <- array(dim=c(nx, vdim, repet))
    for (i in 1:length(all$Z$data)) {
       Res[ , , i] <-
        RFinterpolate(model=model, x=x, y=y, z=z, T=T, grid=grid,
                      distances=distances, dim=dim,
                      data = all$Z$data[[i]], given = all$Z$coords,
                      err.model=err.model, ...,
                      spConform = FALSE, return_variance=FALSE)      
    }
    dim(Res) <- c(nx * vdim, repet)
  } else { ## length(all$Z$data) == 1   
    exact <- RFopt$general$exact
    maxn <- RFopt$krige$locmaxn
    ngiven <- as.integer(all$Z$coords[[1]]$restotal) ## number of given points
    split <- RFopt$krige$locsplitn[NEIGHB_SPLIT+1]

    split <- ngiven > maxn || (!is.na(exact) && !exact && ngiven > split)

    data <- RFboxcox(all$Z$data[[1]], vdim=vdim)
    
    .Call(C_set_boxcox, c(Inf, 0))
 
    if (imputing) {
      Res <- rep(list(data), L)
    } else {
      Res <- rep(list(matrix(nrow=nx, ncol=repet * vdim)), L)
    }
    if (return.variance) sigma2 <- rep(list(NULL), L)  ## currently just a dummy
    names(Res) <- ModelAbbreviations(all$model)
   
    if (split) {
      ## to do:
      all$X <- ExpandGrid(all$X) ## to  do
      all$Z$coords[[1]] <- ExpandGrid(all$Z$coords[[1]]) ## to  do
      
      ## neighbourhood kriging !
      if (!is.na(exact) && exact)
        stop("number of conditioning locations too large for an exact result.")
      if (ngiven > maxn && is.na(exact) &&
          RFopt$basic$printlevel>=PL_IMPORTANT)
        message("performing neighbourhood kriging")

   #   stop("neighbourhood kriging currently not programmed")

      ## calculate the boxes for the locations where we will interpolate
      idx <- GetNeighbourhoods(
          model = all$model[[1]],
          Z=all$Z,
          X=all$X, ## newlocations; to do: grid
          splitfactor=RFopt$krige$locsplitfactor,
          maxn=RFopt$krige$locmaxn,
          split_vec = RFopt$krige$locsplitn,
          shared = TRUE
          )


      totalparts <- length(idx[[2]])
      
      if (totalparts > 1) RFoptions(general.pch="")
      pr <- totalparts > 1 && RFopt$general$pch != "" &&RFopt$general$pch != " "

      for (p in 1:totalparts) {
        stopifnot((Nx <- as.integer(length(idx[[3]][[p]]))) > 0)
        if (pr && p %% 5==0) cat(RFopt$general$pch)
        givenidx <- unlist(idx[[1]][idx[[2]][[p]]])

        if (ignore.trend) 
          initRFlikelihood(all$krige,# including error structure
                           grid=FALSE,
                           x=all$Z$coords[[1]]$x[givenidx,  , drop=FALSE],
                           data=data[givenidx, , drop=FALSE],
                           ignore.trend = ignore.trend,
                           Reg=reg, RFopt=RFopt)
        else
          rflikelihood(all$krige, # including error structure
                       grid=FALSE,
                       x=all$Z$coords[[1]]$x[givenidx,  , drop=FALSE],
                       data=data[givenidx, , drop=FALSE],
                       Reg=reg, RFopt=RFopt)
	for (m in 1:L) {
	  res <- predictGauss(Reg=reg,
                              model=all$model[[m]], # without error structure
			      x = all$X$x[idx[[3]][[p]], ], grid = FALSE,
			      kriging_variance=FALSE) 
        
          if (imputing) {
            ## TO DO : idx[[3]] passt nicht, da sowohl fuer Daten
            ##         als auch coordinaten verwendet wird. Bei repet > 1
            ##         ist da ein Problem -- ueberpruefen ob repet=1
          
            where <- all$data.na[idx[[3]][[p]]]  ## to do:grid
            isNA <- is.na(Res[[m]][where, ])
            Res[[m]][where, ][isNA] <- res[isNA]        
          } else {
            Res[[m]][idx[[3]][[p]], ] <- res
          }
        } ## for p in totalparts
        if (pr) cat("\n")
      }
    } else { ## no splits
##      Print(all$krige, Reg=reg, x=all$Z$coords, data=data,
  ##          ignore.trend = ignore.trend)
    ##  ccccc
      
      if (ignore.trend) 
        initRFlikelihood(all$krige, x=all$Z$coords, data=data,
                         ignore.trend = ignore.trend, Reg=reg, RFopt=RFopt)
      else rflikelihood(all$krige, x=all$Z$coords, data=data,
                        Reg = reg, RFopt=RFopt)
      for (m in 1:L) {
        Res[[m]] <- predictGauss(Reg=reg, model=all$model[[m]], x=all$X,
                                 kriging_variance=FALSE)
      }
    }
  } ## !is.list(Z)

  Z <- all$Z ## achtung! oben kann sich noch all$Z aendern!
  X <- all$X

  spConform <- RFopt$general$spConform

  for (m in 1:L) {
    if (FALSE) {## jonas
      if (return.variance && length(newdim <-
				      c(dimension, if (vdim>1) vdim)) > 1)
	base::dim(sigma2[[m]]) <- newdim
    }
    if (length(newdim)>1) base::dim(Res[[m]]) <- newdim
    else Res[[m]] <- as.vector(Res[[m]])
    if (!is.null(Z$varnames)) attributes(Res[[m]])$varnames <- Z$varnames
    Res[[m]] <- RFboxcox(data=Res[[m]], boxcox = boxcox, inverse=TRUE,vdim=vdim)
  }
  
  if (!spConform && !imputing) {
    if (vdim > 1 && RFopt$general$vdim_close_together) {
      Resperm <- c(length(dimension)+1, 1:length(dimension),
                   if(repet>1) length(dimension)+2)
      for (m in 1:L) {
        Res[[m]] <- aperm(Res[[m]], perm=Resperm)
        if (return.variance)
          sigma2[[m]] <- aperm(sigma2[[m]],
                               perm=Resperm[1:(length(dimension)+1)])
      }
    }
    if (return.variance)
      for (m in 1:L) Res[[m]] <- list(estim = Res[[m]], var = sigma2[[m]])
    return( if (L == 1) Res[[1]] else Res)
  }

  if (imputing) {
    for (m in 1:L) {
      Res[[m]] <- FinishImputing(data=data, simu=Res[[m]], Z=Z,
                                 spConform=spConform,
                                 fillall = RFopt$krige$fillall) ## to do : grid
      if (return.variance){
        var <- FinishImputing(data=data, simu=sigma2[[m]], Z=Z,
                              spConform=spConform,
                              fillall = RFopt$krige$fillall)# to do : grid
        if (spConform) {
          names(var@data) <- paste("var.", names(var@data), sep="")
          Res[[m]]@.RFparams$has.variance <- TRUE
          Res[[m]] <-  cbind(Res[[m]], var)
        } else Res[[m]] <- list(Res[[m]], var)
      }
    }
    return( if (L == 1) Res[[1]] else Res)
  } else {
    for (m in 1:L) {
      Res[[m]] <- conventional2RFspDataFrame(Res[[m]], coords=coords$x,
                                              gridTopology=gridTopology,
                                              n=repet, vdim=vdim, T = coords$T,
                                              vdim_close_together =
                                              RFopt$general$vdim_close_together)
      
      if (return.variance){
        var <- conventional2RFspDataFrame(sigma2[[m]], coords=coords$x,
                                          gridTopology=gridTopology,
                                          n=1, vdim=vdim, T = coords$T,
                                          vdim_close_together =
                                          RFopt$general$vdim_close_together)
        names(var@data) <- paste("var.", names(var@data), sep="")
        Res[[m]]@.RFparams$has.variance <- TRUE
        Res[[m]] <-  cbind(Res[[m]], var)
      }
    }
  }
  
#  Res@.RFparams$krige.method <-
#    c("Simple Kriging", "Ordinary Kriging", "Kriging the Mean",
#      "Universal Kriging", "Intrinsic Kriging")[krige.meth.nr]
  

  ## Res@.RFparams$var <- sigma2 ## sehr unelegant.
  ## * plot(Res) sollte zwei Bilder zeigen
  ## * var(Res) sollte sigma2 zurueckliefern
  ## * summary(Res) auch summary der varianz, falls vorhanden
  ## * summary(Res) auch die Kriging methode

  if (is.raster(x)) {
    for (m in 1:L) {
      Res[[m]] <- raster::raster(Res[[m]])
      raster::projection(Res[[m]]) <- raster::projection(x)
    }
  }
  
  return( if (L == 1) Res[[1]] else Res)
}


rfCondGauss <- function(model, x, y=NULL, z=NULL, T=NULL, grid, n=1,
                        data,   # first coordinates, then data
                        given=NULL, ## alternative for coordinates of data
                        params=NULL,
                        err.model=NULL, err.params, ...) { # ... wegen der Variablen

 
   dots <- list(...)
   if ("spConform" %in% names(dots)) dots$spConform <- NULL

  RFoptOld <- internal.rfoptions(...) 
  on.exit(RFoptions(LIST=RFoptOld[[1]]))
  RFopt <- RFoptOld[[2]]
  boxcox <- .Call(C_get_boxcox)
  cond.reg <- RFopt$registers$register

  all <- rfPrepareData(model=model, x=x, y=y, z=z, T=T, grid=grid,
                       data=data, given=given, params=params,
                       RFopt=RFopt, reg=MODEL_KRIGE,
                       err.model = err.model, err.params=err.params,...)
  Z <- all$Z
  X <- all$X
  simu.grid <- X$grid
  tsdim <- Z$tsdim
  vdim <- Z$vdim
  allowZero <- RFopt$general$allowdistanceZero 
  if (allowZero && !hasArg(err.model))
    stop("in case of 'allowdistanceZero=TRUE' an error model must be given.")

  data <- RFboxcox(Z$data[[1]], vdim=vdim)
  .Call(C_set_boxcox, c(Inf, 0))

  if (all$Z$repetitions != 1)
     stop("conditional simulation allows only for a single data set")
  
  txt <- "kriging in space time dimensions>3 where not all the point ly on a grid is not possible yet"
  ## if 4 dimensional then the last coordinates should ly on a grid

  ## now check whether and if so, which of the given points belong to the
  ## points where conditional simulation takes place
  coords <- ExpandGrid(Z$coords[[1]])
  simu <- NULL
  if (simu.grid) {     
    xgr <- cbind(X$x, X$T)
    l <- ncol(xgr)

#    print(coords$x)
 #   print(xgr)
    
    ind <- 1 + (t(coords$x) - xgr[1, ]) / xgr[2, ] 
    index <- round(ind)
    outside.grid <- allowZero |
      apply((abs(ind-index)>RFopt$general$gridtolerance) | (index<1) |
            (index > 1 + xgr[3, ]), 2, any)

#    print(ind-index)
#    print(t(coords$x) - xgr[1, ])
#    print((t(coords$x) - xgr[1, ]) / xgr[2, ] )
    
#    Print(allowZero, ind, index, outside.grid, (abs(ind-index)>RFopt$general$gridtolerance), index<1, (index > 1 + xgr[3, ]))
    
    if (any(outside.grid)) {     
      ## at least some data points are not on the grid:
      ## simulate as if there is no grid
      simu.grid <- FALSE
 
      if (l>3) stop(txt)
      xx <- if (l==1) ## dim x locations
             matrix(seq(from=xgr[1], by=xgr[2], len=xgr[3]),
                        nrow=1)
            else eval(parse(text=paste("t(expand.grid(",
                            paste("seq(from=xgr[1,", 1:l, 
                                  "], by=xgr[2,", 1:l,
                                  "], len=xgr[3,", 1:l, "])", collapse=","),
                         "))")))  
      ll <- eval(parse(text=paste("c(",
                   paste("length(seq(from=xgr[1,", 1:l, 
	                 "], by=xgr[2,", 1:l, 
		         "], len=xgr[3,", 1:l, "]))",
                         collapse=","),
                   ")")))

      new.index <- rep(0,ncol(index))
      ## data points that are on the grid, must be registered,
      ## so that they can be used as conditioning points of the grid
      if (!all(outside.grid)) {
        new.index[!outside.grid] <- 1 +
          colSums((index[, !outside.grid, drop=FALSE]-1) *
                  cumprod(c(1, ll[-length(ll)])))
      }
      index <- new.index
      new.index <- NULL
    } else {
##      Print("GRID")
      ## data points are all lying on the grid
      simu <- do.call(RFsimulate, args=c(list(model=all$krige,
                                      x=X$x, # y=y, z=z,
                                      T=X$T,
                                      grid=X$grid,
                                      n=n, 
                                      register=cond.reg,
                                      seed = NA),
                                      dots, list(spConform=FALSE)))
 
##    Print(simu, all$krige, n, mean(simu), mean(simu[,,1])); kkk
      ## for all the other cases of simulation see, below
      if (is.vector(simu)) dim(simu) <- c(length(simu), 1)
      else if (!is.matrix(simu)) { ## 3.1.26 is programmed differently
        nvdim <- (vdim > 1) + (n > 1)
        if (nvdim > 0) {
          d <- dim(simu)
          last <- length(d) + 1 - (1 : nvdim)
          dim(simu) <- c(prod(d[-last]), prod(d[last]))
        } else dim(simu) <- c(length(simu), 1)
      }
      
      cum <- cumprod(c(1, xgr[3, -ncol(xgr)]))
      index <- as.vector(1 + cum %*% (index - 1))

      if (is.vector(simu)) dim(simu) <- c(length(simu), 1)
      total <- dim(simu)[1]
      simu.given <-  do.call("[", c(list(simu, index, drop=FALSE),
                                    as.list(rep(TRUE,length(dim(simu))-1))))
     }
  } else { ## not simu.grid
    xx <- t(X$x)  ## dim x locations
   
    ## the next step can be pretty time consuming!!!
    ## to.do: programme it in C
    ##
    ## identification of the points that are given twice, as points to
    ## be simulated and as data points (up to a tolerance distance !)
    ## this is important in case of nugget effect, since otherwise
    ## the user will be surprised not to get the value of the data at
    ## that point
    one2ncol.xx <- 1:ncol(xx)
    index <- if (allowZero) rep(0, nrow(coords$x))
             else apply(coords$x, 1, function(u){
               i <- one2ncol.xx[colSums(abs(xx-u)) <RFopt$general$gridtolerance]
               if (length(i)==0) return(0)
               if (length(i)==1) return(i)
               return(NA)
             })
  }
  
  if (!simu.grid) {
    ## otherwise the simulation has already been performed (see above)
    tol <- RFopt$general$gridtolerance * nrow(xx)
    if (any(is.na(index)))
      stop("identification of the given data points is not unique - `tol' too large?")
    if (any(notfound <- (index==0))) {
      index[notfound] <- (ncol(xx) + 1) : (ncol(xx) + sum(notfound))
    }

    xx <- rbind(t(xx), coords$x[notfound, , drop=FALSE])

##    Print(model=all$krige, x=xx, grid=FALSE, n=n,
  ##                      register = cond.reg, seed = NA, dots)

    simu <- do.call(RFsimulate,
                    args=c(list(model=all$krige, x=xx, grid=FALSE, n=n,
                        register = cond.reg, seed = NA), dots,
                        spConform=FALSE, examples_reduced = FALSE))
    rm("xx")
    if (is.vector(simu)) dim(simu) <- c(length(simu), 1)
    simu.given <-  do.call("[", c(list(simu, index, drop=FALSE),
                                      as.list(rep(TRUE, length(dim(simu))-1))))

    simu <- do.call("[", c(list(simu, 1:X$restotal, drop=FALSE),
                           as.list(rep(TRUE, length(dim(simu))-1))))
    
  }



##  Print("xx", simu, all$krige, mean(simu))
 
  ## to do: als Naeherung bei UK, OK:
  ## kriging(data, method="A") + simu - kriging(simu, method="O") !

  d <- dim(data)
  data <- as.vector(data) - simu.given
#  Print(d, data, simu.given, length(simu.given) / prod(d))
  dim(data) <- c(d, length(simu.given) / prod(d))
 # Print(data)
  
  stopifnot(length(X$y)==0, length(X$z)==0)
  interpol <- RFinterpolate(x=X, model=model,
                            err.model = err.model,
                            register=MODEL_KRIGE,
                            given = coords,
                            data = data,
                            spConform=FALSE, ignore.trend = TRUE)
  
 # Print(X, given, data, simu, interpol, index)
  
  simu <- as.vector(simu) + as.vector(interpol)
  dim(simu) <- c(if (X$grid) X$x[3,] else X$restotal,
                 if (vdim>1) vdim, if (n > 1) n)
  
  simu <- RFboxcox(data=simu, boxcox = boxcox, inverse=TRUE, vdim=vdim)
  
  if (all$imputing) {
    return(FinishImputing(data=Z$data[[1]], simu=simu, Z=Z,
                          spConform=RFopt$general$spConform,
                          fillall = RFopt$krige$fillall))
  }

  attributes(simu)$varnames <- Z$varnames
  attributes(simu)$coordnames <- Z$coordnames


 ## Print(simu)
  ##  Print("endw")
  return(simu)
  
}
